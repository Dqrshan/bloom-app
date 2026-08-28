import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/cycle.dart';
import '../models/day_note.dart';
import '../models/chat_message.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static String? _customPath;
  static void setCustomPath(String path) {
    _customPath = path;
    _cache = null;
  }

  static Map<String, dynamic>? _cache;

  Future<String> get _dbPath async {
    if (_customPath != null) return _customPath!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/bloom_data.json';
    } catch (_) {
      return '${Directory.systemTemp.path}/bloom_data.json';
    }
  }

  Future<Map<String, dynamic>> _getData() async {
    if (_cache != null) return _cache!;
    final path = await _dbPath;
    final file = File(path);
    if (!await file.exists()) {
      _cache = {'cycles': [], 'notes': [], 'conversations': []};
      return _cache!;
    }
    try {
      final content = await file.readAsString();
      _cache = jsonDecode(content) as Map<String, dynamic>;
      _cache!['cycles'] ??= [];
      _cache!['notes'] ??= [];
      _cache!['conversations'] ??= [];
      return _cache!;
    } catch (_) {
      _cache = {'cycles': [], 'notes': [], 'conversations': []};
      return _cache!;
    }
  }

  Future<void> _saveData() async {
    if (_cache == null) return;
    final path = await _dbPath;
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(_cache));
  }

  // --- Cycles ---
  Future<List<Cycle>> getAllCycles() async {
    final data = await _getData();
    final list = data['cycles'] as List? ?? [];
    return list
        .map((c) => Cycle.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  Future<List<Cycle>> getRecentCycles(int limit) async {
    final all = await getAllCycles();
    return all.take(limit).toList();
  }

  Future<Cycle?> getLatestCycle() async {
    final all = await getAllCycles();
    return all.isEmpty ? null : all.first;
  }

  Future<Cycle?> getCycleById(int id) async {
    final all = await getAllCycles();
    return all.where((c) => c.id == id).firstOrNull;
  }

  Future<Cycle?> getCycleStartingOn(DateTime date) async {
    final all = await getAllCycles();
    final d = DateTime(date.year, date.month, date.day);
    for (final c in all) {
      final start = DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
      if (start == d) return c;
    }
    return null;
  }

  Future<int> insertCycle(Cycle cycle) async {
    final data = await _getData();
    final list = data['cycles'] as List;

    final startDay = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
    final existingIdx = list.indexWhere((c) {
      final cStart = DateTime.fromMillisecondsSinceEpoch(c['startDate'] as int);
      return DateTime(cStart.year, cStart.month, cStart.day) == startDay;
    });

    if (existingIdx >= 0) {
      final existingId = list[existingIdx]['id'] as int;
      final updated = cycle.copyWith(id: existingId);
      list[existingIdx] = updated.toMap();
      await _saveData();
      return existingId;
    }

    final id = list.isEmpty
        ? 1
        : ((list.map((c) => (c['id'] as int?) ?? 0).reduce((a, b) => a > b ? a : b)) + 1);
    final withId = cycle.copyWith(id: id);
    list.add(withId.toMap());
    await _saveData();
    return id;
  }

  Future<void> updateCycle(Cycle cycle) async {
    final data = await _getData();
    final list = data['cycles'] as List;
    final idx = list.indexWhere((c) => c['id'] == cycle.id);
    if (idx >= 0) {
      list[idx] = cycle.toMap();
      await _saveData();
    }
  }

  Future<void> deleteCycle(int id) async {
    final data = await _getData();
    (data['cycles'] as List).removeWhere((c) => c['id'] == id);
    await _saveData();
  }

  Future<void> deleteAllCycles() async {
    final data = await _getData();
    data['cycles'] = [];
    await _saveData();
  }

  // --- Day Notes ---
  Future<List<DayNote>> getAllNotes() async {
    final data = await _getData();
    final list = data['notes'] as List? ?? [];
    return list
        .map((n) => DayNote.fromMap(Map<String, dynamic>.from(n as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<DayNote?> getNoteForDate(DateTime date) async {
    final all = await getAllNotes();
    final d = DateTime(date.year, date.month, date.day);
    for (final n in all) {
      final nd = DateTime(n.date.year, n.date.month, n.date.day);
      if (nd == d) return n;
    }
    return null;
  }

  Future<DayNote?> getNoteById(int id) async {
    final all = await getAllNotes();
    return all.where((n) => n.id == id).firstOrNull;
  }

  Future<int> insertNote(DayNote note) async {
    final data = await _getData();
    final list = data['notes'] as List;
    final id = list.isEmpty
        ? 1
        : ((list.map((n) => (n['id'] as int?) ?? 0).reduce((a, b) => a > b ? a : b)) + 1);
    final withId = note.copyWith(id: id);
    list.add(withId.toMap());
    await _saveData();
    return id;
  }

  Future<void> updateNote(DayNote note) async {
    final data = await _getData();
    final list = data['notes'] as List;
    final idx = list.indexWhere((n) => n['id'] == note.id);
    if (idx >= 0) {
      list[idx] = note.toMap();
      await _saveData();
    }
  }

  Future<void> deleteNote(int id) async {
    final data = await _getData();
    (data['notes'] as List).removeWhere((n) => n['id'] == id);
    await _saveData();
  }

  Future<void> deleteAllNotes() async {
    final data = await _getData();
    data['notes'] = [];
    await _saveData();
  }

  // --- Bloom AI Chat Conversations & History (CRUD) ---
  Future<List<ChatConversation>> getAllConversations() async {
    final data = await _getData();
    final list = data['conversations'] as List? ?? [];
    return list
        .map((c) => ChatConversation.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<ChatConversation?> getConversationById(String id) async {
    final all = await getAllConversations();
    return all.where((c) => c.id == id).firstOrNull;
  }

  Future<void> saveConversation(ChatConversation conversation) async {
    final data = await _getData();
    final list = data['conversations'] as List;
    final idx = list.indexWhere((c) => c['id'] == conversation.id);
    if (idx >= 0) {
      list[idx] = conversation.toMap();
    } else {
      list.add(conversation.toMap());
    }
    await _saveData();
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final conv = await getConversationById(id);
    if (conv != null) {
      await saveConversation(conv.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> deleteConversation(String id) async {
    final data = await _getData();
    (data['conversations'] as List).removeWhere((c) => c['id'] == id);
    await _saveData();
  }

  Future<void> deleteChatMessage(String conversationId, String messageId) async {
    final conv = await getConversationById(conversationId);
    if (conv != null) {
      final updatedMessages = conv.messages.where((m) => m.id != messageId).toList();
      await saveConversation(conv.copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> clearAllConversations() async {
    final data = await _getData();
    data['conversations'] = [];
    await _saveData();
  }

  // --- Export, Import & Sync Merge ---
  Future<Map<String, dynamic>> exportAll() async {
    final data = await _getData();
    return {
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'cycles': data['cycles'] ?? [],
      'notes': data['notes'] ?? [],
      'conversations': data['conversations'] ?? [],
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    _cache = {
      'cycles': (data['cycles'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      'notes': (data['notes'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      'conversations': (data['conversations'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    };
    await _saveData();
  }

  Future<int> mergeIncomingData(Map<String, dynamic> incoming) async {
    final currentCycles = await getAllCycles();
    final currentNotes = await getAllNotes();
    int mergedCount = 0;

    // Merge Cycles
    final rawCycles = incoming['cycles'] as List? ?? [];
    for (final raw in rawCycles) {
      final incomingCycle = Cycle.fromMap(Map<String, dynamic>.from(raw as Map));
      final incomingStartDay = DateTime(
        incomingCycle.startDate.year,
        incomingCycle.startDate.month,
        incomingCycle.startDate.day,
      );

      final matchIdx = currentCycles.indexWhere((c) {
        final cStart = DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
        return c.id == incomingCycle.id || cStart == incomingStartDay;
      });

      if (matchIdx >= 0) {
        final existing = currentCycles[matchIdx];
        if (incomingCycle.updatedAt.isAfter(existing.updatedAt)) {
          await updateCycle(incomingCycle.copyWith(id: existing.id));
          mergedCount++;
        }
      } else {
        await insertCycle(incomingCycle);
        mergedCount++;
      }
    }

    // Merge Notes
    final rawNotes = incoming['notes'] as List? ?? [];
    for (final raw in rawNotes) {
      final incomingNote = DayNote.fromMap(Map<String, dynamic>.from(raw as Map));
      final noteDate = DateTime(incomingNote.date.year, incomingNote.date.month, incomingNote.date.day);

      final matchIdx = currentNotes.indexWhere((n) {
        final nDate = DateTime(n.date.year, n.date.month, n.date.day);
        return n.id == incomingNote.id || nDate == noteDate;
      });

      if (matchIdx >= 0) {
        final existing = currentNotes[matchIdx];
        if (incomingNote.updatedAt.isAfter(existing.updatedAt)) {
          await updateNote(incomingNote.copyWith(id: existing.id));
          mergedCount++;
        }
      } else {
        await insertNote(incomingNote);
        mergedCount++;
      }
    }

    return mergedCount;
  }

  Future<void> deleteAll() async {
    _cache = {'cycles': [], 'notes': [], 'conversations': []};
    await _saveData();
  }
}
