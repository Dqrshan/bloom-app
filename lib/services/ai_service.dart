import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle.dart';
import '../models/day_note.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String defaultApiKey =
      String.fromEnvironment('BLOOM_AI_KEY', defaultValue: '');
  static const String defaultModel = 'meta/llama-3.2-11b-vision-instruct';
  static const String endpoint =
      String.fromEnvironment('BLOOM_AI_ENDPOINT', defaultValue: 'https://integrate.api.nvidia.com/v1/chat/completions');

  String _apiKey = defaultApiKey;
  String _model = defaultModel;

  String get apiKey => _apiKey;
  String get model => _model;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('bloom_ai_api_key') ?? defaultApiKey;
    _model = prefs.getString('bloom_ai_model') ?? defaultModel;
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim().isEmpty ? defaultApiKey : key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bloom_ai_api_key', _apiKey);
  }

  Future<void> setModel(String modelName) async {
    _model = modelName.trim().isEmpty ? defaultModel : modelName.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bloom_ai_model', _model);
  }

  /// Internal Bloom AI Chat Completion caller
  Future<String> _callBloomAI({
    required List<Map<String, String>> messages,
    double temperature = 0.6,
    int maxTokens = 300,
  }) async {
    if (_apiKey.isEmpty) await init();

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final msg = choices[0]['message'] as Map<String, dynamic>?;
        final content = msg?['content'] as String?;
        if (content != null) {
          return content.trim().replaceAll('"', '');
        }
      }
      return 'Welcome to Bloom! Track your cycle with confidence today.';
    } else {
      throw Exception('Bloom AI Service Error (${response.statusCode}): ${response.body}');
    }
  }

  /// 1. Dynamic Personalized Daily Greeting & Insight
  Future<String> generateDailyInsight({
    required int? cycleDay,
    required bool isOnPeriod,
    required int averageCycleLength,
    required int averagePeriodLength,
    DayNote? todayNote,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = 'bloom_ai_insight_${DateTime.now().toIso8601String().substring(0, 10)}';
    final cached = prefs.getString(todayKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    String phase = 'Follicular phase';
    if (isOnPeriod) {
      phase = 'Menstrual phase (Period)';
    } else if (cycleDay != null) {
      if (cycleDay <= averagePeriodLength) {
        phase = 'Menstrual phase';
      } else if (cycleDay <= (averageCycleLength ~/ 2) - 2) {
        phase = 'Follicular phase (Energy rising)';
      } else if (cycleDay <= (averageCycleLength ~/ 2) + 2) {
        phase = 'Ovulatory phase (Fertile window)';
      } else {
        phase = 'Luteal phase (Nurture & Rest)';
      }
    }

    final prompt = StringBuffer();
    prompt.writeln('User cycle status:');
    prompt.writeln('- Cycle Day: ${cycleDay ?? "Not set yet"}');
    prompt.writeln('- Phase: $phase');
    prompt.writeln('- Is on active period: $isOnPeriod');
    if (todayNote != null) {
      if (todayNote.mood != null) prompt.writeln('- Mood: ${todayNote.mood}');
      if (todayNote.crampsSeverity > 0) prompt.writeln('- Cramp severity: ${todayNote.crampsSeverity}/10');
      if (todayNote.symptoms.isNotEmpty) prompt.writeln('- Symptoms: ${todayNote.symptoms.join(", ")}');
    }

    try {
      final text = await _callBloomAI(
        messages: [
          {
            'role': 'system',
            'content':
                'You are Bloom AI, an empathetic, caring cycle wellness assistant. Write a warm 2-sentence daily greeting and personalized physiological tip for the user based on their cycle day and phase. Keep it gentle, uplifting, concise, and scientifically grounded.',
          },
          {'role': 'user', 'content': prompt.toString()},
        ],
        maxTokens: 120,
      );

      await prefs.setString(todayKey, text);
      return text;
    } catch (_) {
      return isOnPeriod
          ? 'Take it gentle today. Hydrate well, apply gentle warmth if experiencing cramps, and allow yourself extra rest.'
          : 'Embrace your natural energy today! Focus on nourishing meals, mindful movement, and listening to your body.';
    }
  }

  /// 2. Comprehensive AI Cycle & Health Analysis
  Future<Map<String, dynamic>> generateFullCycleAnalysis({
    required List<Cycle> cycles,
    required List<DayNote> notes,
    required int averageCycleLength,
    required int averagePeriodLength,
  }) async {
    final prompt = StringBuffer();
    prompt.writeln('Cycles summary:');
    prompt.writeln('- Total cycles logged: ${cycles.length}');
    prompt.writeln('- Average cycle length: $averageCycleLength days');
    prompt.writeln('- Average period length: $averagePeriodLength days');
    if (cycles.isNotEmpty) {
      prompt.writeln('- Recent cycles:');
      for (final c in cycles.take(4)) {
        prompt.writeln('  * Start: ${c.startDate.toIso8601String().substring(0, 10)}, Period length: ${c.periodLength ?? "ongoing"}');
      }
    }
    if (notes.isNotEmpty) {
      final symptomCounts = <String, int>{};
      for (final n in notes) {
        for (final s in n.symptoms) {
          symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
        }
      }
      prompt.writeln('- Frequent symptoms: ${symptomCounts.entries.map((e) => "${e.key} (${e.value}x)").join(", ")}');
    }

    try {
      final responseText = await _callBloomAI(
        messages: [
          {
            'role': 'system',
            'content':
                'You are Bloom AI, an expert women’s hormonal health and cycle analyst. Analyze the user cycle and symptom data. Provide a JSON response with keys: "regularity" (string assessment), "hormonal_phase_overview" (string), "symptom_patterns" (string), "nutrition_tips" (array of 3 strings), "movement_tips" (array of 3 strings), and "partner_support_tip" (string). Output valid JSON only without markdown code blocks.',
          },
          {'role': 'user', 'content': prompt.toString()},
        ],
        temperature: 0.4,
        maxTokens: 550,
      );

      final cleanJson = responseText.replaceAll(RegExp(r'```json|```'), '').trim();
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (_) {
      return {
        'regularity': 'Your cycles show a healthy baseline average of $averageCycleLength days.',
        'hormonal_phase_overview':
            'Your hormones fluctuate across four rhythmic phases: Menstrual, Follicular, Ovulatory, and Luteal.',
        'symptom_patterns':
            'Symptoms such as mild cramping and fatigue are common pre-menstrually and respond well to hydration and magnesium.',
        'nutrition_tips': [
          'Incorporate iron-rich leafy greens and vitamin C during your period.',
          'Support liver estrogen processing with cruciferous veggies during follicular phase.',
          'Focus on healthy fats and magnesium-rich pumpkin seeds in the luteal phase.'
        ],
        'movement_tips': [
          'Gentle stretching, restorative yoga, and walks during menstruation.',
          'Higher intensity training and strength building during the follicular phase.',
          'Moderate Pilates and light cardio during the luteal phase.'
        ],
        'partner_support_tip':
            'Keep hot tea, heating pads, and nourishing snacks readily accessible to provide comforting support.'
      };
    }
  }

  /// 3. AI Partner Empathy Guide
  Future<String> generatePartnerTip({
    required int? cycleDay,
    required bool isOnPeriod,
    DayNote? latestNote,
  }) async {
    final prompt = StringBuffer();
    prompt.writeln('Partner cycle status:');
    prompt.writeln('- Cycle Day: ${cycleDay ?? "Unknown"}');
    prompt.writeln('- Is on period: $isOnPeriod');
    if (latestNote != null) {
      if (latestNote.mood != null) prompt.writeln('- Logged mood: ${latestNote.mood}');
      if (latestNote.crampsSeverity > 0) prompt.writeln('- Cramp level: ${latestNote.crampsSeverity}/10');
      if (latestNote.symptoms.isNotEmpty) prompt.writeln('- Symptoms: ${latestNote.symptoms.join(", ")}');
    }

    try {
      return await _callBloomAI(
        messages: [
          {
            'role': 'system',
            'content':
                'You are Bloom AI Partner Guide. Provide 2-3 loving, practical, and empathetic tips for a partner to support their significant other today based on their cycle day and symptoms. Keep it compassionate, actionable, and encouraging.',
          },
          {'role': 'user', 'content': prompt.toString()},
        ],
        maxTokens: 200,
      );
    } catch (_) {
      return 'Show extra care today! Offer a warm beverage, check in with an encouraging word, and help take care of daily chores.';
    }
  }

  /// 4. AI Symptom Relief Helper
  Future<String> generateSymptomRelief({
    required List<String> symptoms,
    required int crampSeverity,
    required String? mood,
  }) async {
    try {
      return await _callBloomAI(
        messages: [
          {
            'role': 'system',
            'content':
                'You are Bloom AI Holistic Health Advisor. Given the user’s logged symptoms, mood, and cramp level, provide 3 actionable, comforting, natural relief suggestions (herbal, dietary, heat/movement). Format as bullet points.',
          },
          {
            'role': 'user',
            'content':
                'Symptoms: ${symptoms.isEmpty ? "General discomfort" : symptoms.join(", ")}, Cramps: $crampSeverity/10, Mood: ${mood ?? "neutral"}',
          },
        ],
        maxTokens: 250,
      );
    } catch (_) {
      return '• Apply a warm heating pad to your lower abdomen or lower back for 15–20 minutes.\n• Sip warm chamomile, peppermint, or ginger tea to relax muscles and soothe digestion.\n• Practice gentle child’s pose or pelvic tilts to relieve tension.';
    }
  }

  /// 5. Interactive Chat with Bloom AI (with Guardrails & Context Memory)
  Future<String> askBloomAI(
    String question,
    List<Map<String, String>> history, {
    String? userContext,
  }) async {
    final systemPrompt = StringBuffer();
    systemPrompt.writeln(
      'You are Bloom AI, an intelligent, empathetic, and scientifically accurate cycle wellness and reproductive health companion.',
    );
    systemPrompt.writeln();
    systemPrompt.writeln('=== STRICT TOPIC GUARDRAILS ===');
    systemPrompt.writeln(
      '1. TOPIC RESTRICTION: You MUST ONLY answer questions related to menstrual cycles, periods, hormonal balance, ovulation, fertility, PMS, mood swings, physical/emotional symptoms, nutrition, cycle-syncing, holistic natural remedies, intimacy, and partner empathy.',
    );
    systemPrompt.writeln(
      '2. OFF-TOPIC REFUSAL: If the user asks about unrelated topics (such as coding, general technology, politics, sports, math, celebrities, trivia, or any non-wellness subject), you MUST politely and warmly decline and redirect back to their health. For example: "I am Bloom AI, your personal cycle, mood, and reproductive wellness companion 🌸. I can only assist with questions related to periods, hormonal health, symptoms, moods, fertility, and wellness. How are you feeling in your cycle today?"',
    );
    systemPrompt.writeln(
      '3. FORMATTING: Format your responses with clean, readable Markdown: use bullet points (`- `), bold key terms (`**term**`), headers (`###`), short paragraphs, and gentle emojis.',
    );
    systemPrompt.writeln(
      '4. WELLNESS DISCLAIMER: Clarify you provide clinical wellness and holistic lifestyle guidance, not medical diagnosis.',
    );

    if (userContext != null && userContext.isNotEmpty) {
      systemPrompt.writeln();
      systemPrompt.writeln('=== USER PERSONAL CYCLE CONTEXT & HEALTH MEMORY ===');
      systemPrompt.writeln(userContext);
      systemPrompt.writeln(
        'Tailor your answers specifically to the user\'s current cycle day, phase, and logged symptoms when relevant.',
      );
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemPrompt.toString(),
      },
      ...history,
      {'role': 'user', 'content': question},
    ];

    try {
      return await _callBloomAI(messages: messages, maxTokens: 450);
    } catch (e) {
      return 'I am currently unable to reach Bloom AI. Please check your network connection ($e).';
    }
  }
}
