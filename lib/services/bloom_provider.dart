import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cycle.dart';
import '../models/day_note.dart';
import '../models/chat_message.dart';
import 'database_service.dart';
import 'sync_service.dart';
import 'ai_service.dart';

class BloomProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  final AIService _ai = AIService();

  List<Cycle> _cycles = [];
  List<DayNote> _notes = [];
  List<ChatConversation> _conversations = [];
  ChatConversation? _currentConversation;
  Cycle? _latestCycle;
  bool _isLoading = true;
  bool _isChatSending = false;
  String? _dailyAIGreeting;
  bool _isAILoading = false;

  List<Cycle> get cycles => _cycles;
  List<DayNote> get notes => _notes;
  List<ChatConversation> get conversations => _conversations;
  ChatConversation? get currentConversation => _currentConversation;
  Cycle? get latestCycle => _latestCycle;
  bool get isLoading => _isLoading;
  bool get isChatSending => _isChatSending;
  String? get dailyAIGreeting => _dailyAIGreeting;
  bool get isAILoading => _isAILoading;
  SyncService get syncService => _sync;
  AIService get aiService => _ai;

  StreamSubscription? _syncStateSub;
  StreamSubscription? _syncDataSub;
  StreamSubscription? _syncPartnerSub;
  StreamSubscription? _syncApprovalSub;
  StreamSubscription? _syncApprovedSub;
  bool _isDisposed = false;

  BloomProvider() {
    _syncStateSub = _sync.stateStream.listen((_) {
      if (!_isDisposed && hasListeners) {
        notifyListeners();
      }
    });
    _syncDataSub = _sync.dataReceivedStream.listen((data) async {
      if (!_isDisposed) {
        await _db.mergeIncomingData(data);
        await loadData();
      }
    });
    _syncPartnerSub = _sync.partnerStream.listen((_) {
      if (!_isDisposed && hasListeners) {
        notifyListeners();
      }
    });
    _syncApprovalSub = _sync.approvalStream.listen((_) {
      if (!_isDisposed && hasListeners) {
        notifyListeners();
      }
    });
    _syncApprovedSub = _sync.syncApprovedStream.listen((_) async {
      if (!_isDisposed) {
        final payload = await _db.exportAll();
        _sync.sendEncryptedSyncData(payload);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncStateSub?.cancel();
    _syncDataSub?.cancel();
    _syncPartnerSub?.cancel();
    _syncApprovalSub?.cancel();
    _syncApprovedSub?.cancel();
    super.dispose();
  }

  // --- Cycle computations ---
  bool get isOnPeriod {
    if (_latestCycle == null) return false;
    return _latestCycle!.isOngoing;
  }

  int? get currentDay {
    if (_latestCycle == null) return null;
    return _latestCycle!.daysSinceStart;
  }

  int get averageCycleLength {
    final completed = _cycles.where((c) => c.cycleLength != null).toList();
    if (completed.isEmpty) return 28;
    final sum = completed.fold<int>(0, (acc, c) => acc + c.cycleLength!);
    return (sum / completed.length).round();
  }

  int get averagePeriodLength {
    final completed = _cycles.where((c) => c.periodLength != null).toList();
    if (completed.isEmpty) return 5;
    final sum = completed.fold<int>(0, (acc, c) => acc + c.periodLength!);
    return (sum / completed.length).round();
  }

  int get totalCycles => _cycles.length;

  DateTime? get predictedNextStart {
    if (_latestCycle == null) return null;
    return _latestCycle!.startDate.add(Duration(days: averageCycleLength));
  }

  List<DateTime> get periodDays {
    final days = <DateTime>{};
    for (final c in _cycles) {
      var d = DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
      final rawEnd = c.endDate ??
          (c.startDate ==
                  DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
              ? DateTime.now()
              : c.startDate.add(Duration(days: (c.periodLength ?? 5) - 1)));
      final end = DateTime(rawEnd.year, rawEnd.month, rawEnd.day);
      while (!d.isAfter(end)) {
        days.add(d);
        d = d.add(const Duration(days: 1));
      }
    }
    return days.toList();
  }

  List<DateTime> get predictedDays {
    final start = predictedNextStart;
    if (start == null) return [];
    final days = <DateTime>[];
    var d = DateTime(start.year, start.month, start.day);
    final end = start.add(Duration(days: averagePeriodLength - 1));
    final finalEnd = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(finalEnd)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return days;
  }

  List<DateTime> get fertileDays {
    final start = predictedNextStart;
    if (start == null) return [];
    final ovulation = start.subtract(const Duration(days: 14));
    final days = <DateTime>[];
    for (var i = -3; i <= 1; i++) {
      final d = ovulation.add(Duration(days: i));
      days.add(DateTime(d.year, d.month, d.day));
    }
    return days;
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    await _sync.init();
    await _ai.init();
    _cycles = await _db.getAllCycles();
    _notes = await _db.getAllNotes();
    _conversations = await _db.getAllConversations();
    _latestCycle = await _db.getLatestCycle();

    if (_currentConversation != null) {
      _currentConversation = await _db.getConversationById(_currentConversation!.id);
    }

    _isLoading = false;
    notifyListeners();

    // Fetch daily AI insight
    await _loadDailyAIGreeting();
  }

  Future<void> _loadDailyAIGreeting() async {
    try {
      final todayNote = await getNoteForDate(DateTime.now());
      _dailyAIGreeting = await _ai.generateDailyInsight(
        cycleDay: currentDay,
        isOnPeriod: isOnPeriod,
        averageCycleLength: averageCycleLength,
        averagePeriodLength: averagePeriodLength,
        todayNote: todayNote,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshDailyAIGreeting() async {
    _isAILoading = true;
    notifyListeners();

    try {
      final todayNote = await getNoteForDate(DateTime.now());
      _dailyAIGreeting = await _ai.generateDailyInsight(
        cycleDay: currentDay,
        isOnPeriod: isOnPeriod,
        averageCycleLength: averageCycleLength,
        averagePeriodLength: averagePeriodLength,
        todayNote: todayNote,
      );
    } catch (_) {}

    _isAILoading = false;
    notifyListeners();
  }

  // --- Cycle & Past Period Logging ---
  Future<void> startPeriod() async {
    final today = DateTime.now();
    await startPeriodForDate(today);
  }

  Future<void> startPeriodForDate(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);

    final existingOnDate = await _db.getCycleStartingOn(day);
    if (existingOnDate != null) {
      await _db.updateCycle(existingOnDate.copyWith(
        startDate: day,
        endDate: null,
      ));
      await loadData();
      return;
    }

    if (_latestCycle != null && _latestCycle!.endDate == null) {
      final prevStart = DateTime(
        _latestCycle!.startDate.year,
        _latestCycle!.startDate.month,
        _latestCycle!.startDate.day,
      );
      if (day.isAfter(prevStart)) {
        final diff = day.difference(prevStart).inDays;
        await _db.updateCycle(_latestCycle!.copyWith(
          endDate: day.subtract(const Duration(days: 1)),
          periodLength: diff <= 0 ? 1 : diff,
        ));
      }
    }

    await _db.insertCycle(Cycle(startDate: day));
    await loadData();
  }

  Future<void> logPastPeriod({
    required DateTime startDate,
    DateTime? endDate,
    int? periodLength,
    String notes = '',
  }) async {
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime? endDay;
    int calculatedPeriodLength = periodLength ?? 5;

    if (endDate != null) {
      endDay = DateTime(endDate.year, endDate.month, endDate.day);
      final diff = endDay.difference(startDay).inDays + 1;
      calculatedPeriodLength = diff > 0 ? diff : 1;
    } else if (periodLength != null) {
      endDay = startDay.add(Duration(days: periodLength - 1));
    }

    final existing = await _db.getCycleStartingOn(startDay);
    if (existing != null) {
      await _db.updateCycle(existing.copyWith(
        startDate: startDay,
        endDate: endDay,
        periodLength: calculatedPeriodLength,
        notes: notes.isNotEmpty ? notes : existing.notes,
      ));
    } else {
      final cycle = Cycle(
        startDate: startDay,
        endDate: endDay,
        periodLength: calculatedPeriodLength,
        notes: notes,
      );
      await _db.insertCycle(cycle);
    }
    await loadData();
  }

  Future<void> endPeriod() async {
    if (_latestCycle == null || _latestCycle!.endDate != null) return;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final rawDiff = day.difference(_latestCycle!.startDate).inDays;
    final periodLength = rawDiff <= 0 ? 1 : rawDiff;
    await _db.updateCycle(_latestCycle!.copyWith(
      endDate: day,
      periodLength: periodLength,
      cycleLength: periodLength + averageCycleLength,
    ));
    await loadData();
  }

  Future<void> deleteCycle(int id) async {
    await _db.deleteCycle(id);
    await loadData();
  }

  // --- Notes ---
  Future<void> saveNote(DayNote note) async {
    if (note.id != null) {
      await _db.updateNote(note);
    } else {
      final existing = await _db.getNoteForDate(note.date);
      if (existing != null) {
        await _db.updateNote(note.copyWith(id: existing.id));
      } else {
        await _db.insertNote(note);
      }
    }
    await loadData();
  }

  Future<void> deleteNote(int id) async {
    await _db.deleteNote(id);
    await loadData();
  }

  Future<DayNote?> getNoteForDate(DateTime date) async {
    return _db.getNoteForDate(date);
  }

  // --- Bloom AI Chat Conversations (CRUD) ---
  Future<ChatConversation> createConversation({String? initialTitle}) async {
    final now = DateTime.now();
    final newConv = ChatConversation(
      id: 'conv_${now.microsecondsSinceEpoch}',
      title: initialTitle ?? 'New Conversation',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
    await _db.saveConversation(newConv);
    _conversations = await _db.getAllConversations();
    _currentConversation = newConv;
    notifyListeners();
    return newConv;
  }

  Future<void> selectConversation(String id) async {
    final conv = await _db.getConversationById(id);
    if (conv != null) {
      _currentConversation = conv;
      notifyListeners();
    }
  }

  Future<void> renameConversation(String id, String newTitle) async {
    await _db.renameConversation(id, newTitle);
    _conversations = await _db.getAllConversations();
    if (_currentConversation?.id == id) {
      _currentConversation = await _db.getConversationById(id);
    }
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    await _db.deleteConversation(id);
    _conversations = await _db.getAllConversations();
    if (_currentConversation?.id == id) {
      _currentConversation = _conversations.isNotEmpty ? _conversations.first : null;
    }
    notifyListeners();
  }

  Future<void> deleteChatMessage(String conversationId, String messageId) async {
    await _db.deleteChatMessage(conversationId, messageId);
    _conversations = await _db.getAllConversations();
    if (_currentConversation?.id == conversationId) {
      _currentConversation = await _db.getConversationById(conversationId);
    }
    notifyListeners();
  }

  Future<void> clearAllConversations() async {
    await _db.clearAllConversations();
    _conversations = [];
    _currentConversation = null;
    notifyListeners();
  }

  Future<void> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    var conv = _currentConversation;
    if (conv == null) {
      final defaultTitle = trimmed.length > 28 ? '${trimmed.substring(0, 28)}...' : trimmed;
      conv = await createConversation(initialTitle: defaultTitle);
    }

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(conv.messages)..add(userMsg);
    final String updatedTitle = (conv.title == 'New Conversation')
        ? (trimmed.length > 28 ? '${trimmed.substring(0, 28)}...' : trimmed)
        : conv.title;

    final updatedConv = conv.copyWith(
      title: updatedTitle,
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    await _db.saveConversation(updatedConv);
    _currentConversation = updatedConv;
    _conversations = await _db.getAllConversations();
    _isChatSending = true;
    notifyListeners();

    try {
      // Build real-time personal cycle context memory for Bloom AI
      final userContext = _buildUserHealthContext();

      // Prepare history for AI context
      final history = conv.messages.take(10).map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          }).toList();

      final aiResponseText = await _ai.askBloomAI(
        trimmed,
        history,
        userContext: userContext,
      );

      final aiMsg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_a',
        text: aiResponseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final withAiResponse = List<ChatMessage>.from(_currentConversation!.messages)..add(aiMsg);
      final finalConv = _currentConversation!.copyWith(
        messages: withAiResponse,
        updatedAt: DateTime.now(),
      );

      await _db.saveConversation(finalConv);
      _currentConversation = finalConv;
      _conversations = await _db.getAllConversations();
    } catch (_) {
      final fallbackMsg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_err',
        text: 'Bloom AI is momentarily unavailable. Please verify your connection and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      final withFallback = List<ChatMessage>.from(_currentConversation!.messages)..add(fallbackMsg);
      final finalConv = _currentConversation!.copyWith(
        messages: withFallback,
        updatedAt: DateTime.now(),
      );
      await _db.saveConversation(finalConv);
      _currentConversation = finalConv;
    } finally {
      _isChatSending = false;
      notifyListeners();
    }
  }

  String _buildUserHealthContext() {
    final ctx = StringBuffer();
    ctx.writeln('- Current cycle day: ${currentDay != null ? "Day $currentDay" : "Not logged yet"}');
    ctx.writeln('- Active period state: ${isOnPeriod ? "Currently on active period (Day ${currentDay ?? 1})" : "Not currently bleeding"}');
    ctx.writeln('- Average cycle length: $averageCycleLength days');
    ctx.writeln('- Average period length: $averagePeriodLength days');
    ctx.writeln('- Total cycles logged: $totalCycles');

    if (_cycles.isNotEmpty) {
      ctx.writeln('- Recent cycles:');
      for (final c in _cycles.take(3)) {
        ctx.writeln('  * Start: ${c.startDate.toIso8601String().substring(0, 10)}, Duration: ${c.periodLength ?? "ongoing"} days');
      }
    }

    if (_notes.isNotEmpty) {
      ctx.writeln('- Recent logged symptoms & moods:');
      for (final n in _notes.take(5)) {
        final sym = n.symptoms.isNotEmpty ? n.symptoms.join(', ') : 'None';
        ctx.writeln('  * ${n.date.toIso8601String().substring(0, 10)}: Mood: ${n.mood ?? "None"}, Flow: ${n.flowLevel ?? "None"}, Cramps: ${n.crampsSeverity}/10, Symptoms: $sym${n.content.isNotEmpty ? ", Note: ${n.content}" : ""}');
      }
    }
    return ctx.toString();
  }

  // --- Export, Import & Clean ---
  Future<Map<String, dynamic>> exportData() async {
    return _db.exportAll();
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await _db.importAll(data);
    await loadData();
  }

  Future<void> deleteAllData() async {
    await _db.deleteAll();
    await loadData();
  }
}
