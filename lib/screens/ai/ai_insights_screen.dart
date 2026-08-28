import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/bloom_provider.dart';
import '../../theme/bloom_theme.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analysis;
  String? _partnerTip;
  final _chatCtrl = TextEditingController();
  final _chatHistory = <Map<String, String>>[];
  bool _isChatLoading = false;

  final _suggestedQuestions = [
    'How do hormones affect mood in the luteal phase?',
    'What natural remedies help with period cramps?',
    'How can my partner support me during PMS?',
    'What foods help balance energy during ovulation?',
  ];

  @override
  void initState() {
    super.initState();
    _loadAIAnalysis();
  }

  Future<void> _loadAIAnalysis() async {
    final prov = context.read<BloomProvider>();
    final ai = prov.aiService;

    try {
      final analysis = await ai.generateFullCycleAnalysis(
        cycles: prov.cycles,
        notes: prov.notes,
        averageCycleLength: prov.averageCycleLength,
        averagePeriodLength: prov.averagePeriodLength,
      );

      final latestNote = prov.notes.isNotEmpty ? prov.notes.first : null;
      final partnerTip = await ai.generatePartnerTip(
        cycleDay: prov.currentDay,
        isOnPeriod: prov.isOnPeriod,
        latestNote: latestNote,
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _partnerTip = partnerTip;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: BloomColors.rose500, size: 20),
            SizedBox(width: 8),
            Text('Bloom AI Health Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate Analysis',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAIAnalysis();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: BloomColors.rose500),
                  SizedBox(height: 16),
                  Text('Analyzing cycles with Bloom AI...', style: TextStyle(color: BloomColors.muted, fontSize: 13)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BloomColors.rose500.withValues(alpha: 0.12),
                        BloomColors.lavender.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BloomColors.rose500.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: BloomColors.rose500.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_awesome, color: BloomColors.rose500, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bloom AI Health Report',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: BloomColors.ink),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Intelligent cycle & hormonal analysis',
                              style: TextStyle(color: BloomColors.inkLight, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Cycle Regularity & Hormonal Rhythm
                if (_analysis != null) ...[
                  _card(
                    'CYCLE HEALTH & REGULARITY',
                    Icons.timeline_rounded,
                    BloomColors.rose500,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _analysis!['regularity'] ?? 'Your cycle follows a healthy hormonal baseline.',
                          style: const TextStyle(fontSize: 14, color: BloomColors.ink, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BloomColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18, color: BloomColors.rose500),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _analysis!['hormonal_phase_overview'] ?? 'Hormonal fluctuations follow 4 distinct biological phases.',
                                  style: const TextStyle(fontSize: 12, color: BloomColors.inkLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Nutrition & Movement Recommendations
                  _card(
                    'CYCLE-SYNCED WELLNESS',
                    Icons.spa_rounded,
                    BloomColors.sage,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nutrition Recommendations',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: BloomColors.ink),
                        ),
                        const SizedBox(height: 6),
                        ...((_analysis!['nutrition_tips'] as List?) ?? []).map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🥗 ', style: TextStyle(fontSize: 13)),
                                  Expanded(child: Text('$tip', style: const TextStyle(fontSize: 13, color: BloomColors.inkLight, height: 1.3))),
                                ],
                              ),
                            )),
                        const SizedBox(height: 12),
                        const Text(
                          'Movement & Energy Syncing',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: BloomColors.ink),
                        ),
                        const SizedBox(height: 6),
                        ...((_analysis!['movement_tips'] as List?) ?? []).map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🧘‍♀️ ', style: TextStyle(fontSize: 13)),
                                  Expanded(child: Text('$tip', style: const TextStyle(fontSize: 13, color: BloomColors.inkLight, height: 1.3))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Partner Support & Empathy Guide
                if (_partnerTip != null)
                  _card(
                    'PARTNER EMPATHY & CARE GUIDE',
                    Icons.favorite_rounded,
                    BloomColors.peach,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _partnerTip!,
                          style: const TextStyle(fontSize: 13, color: BloomColors.ink, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // 4. Ask Bloom AI Interactive Assistant
                _header('ASK BLOOM AI COMPANION'),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ask any question about your cycle, symptoms, fertility, or mood',
                          style: TextStyle(fontSize: 13, color: BloomColors.muted),
                        ),
                        const SizedBox(height: 12),

                        // Suggested prompts
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _suggestedQuestions.map((q) => ActionChip(
                                label: Text(q, style: const TextStyle(fontSize: 11)),
                                backgroundColor: BloomColors.rose50,
                                onPressed: () {
                                  _chatCtrl.text = q;
                                  _askQuestion();
                                },
                              )).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Chat History
                        if (_chatHistory.isNotEmpty) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          ..._chatHistory.map((m) {
                            final isUser = m['role'] == 'user';
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                decoration: BoxDecoration(
                                  color: isUser ? BloomColors.rose500 : BloomColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  m['content'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isUser ? Colors.white : BloomColors.ink,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],

                        // Input field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Type a wellness question...',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onSubmitted: (_) => _askQuestion(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: _isChatLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: BloomColors.rose500),
                                    )
                                  : const Icon(Icons.send_rounded, color: BloomColors.rose500),
                              onPressed: _isChatLoading ? null : _askQuestion,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _askQuestion() async {
    final query = _chatCtrl.text.trim();
    if (query.isEmpty) return;

    final ai = context.read<BloomProvider>().aiService;

    setState(() {
      _chatHistory.add({'role': 'user', 'content': query});
      _chatCtrl.clear();
      _isChatLoading = true;
    });

    try {
      final answer = await ai.askBloomAI(query, _chatHistory);
      if (mounted) {
        setState(() {
          _chatHistory.add({'role': 'assistant', 'content': answer});
          _isChatLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add({'role': 'assistant', 'content': 'Error fetching AI response: $e'});
          _isChatLoading = false;
        });
      }
    }
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: BloomColors.muted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, Color color, Widget content) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color, letterSpacing: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }
}
