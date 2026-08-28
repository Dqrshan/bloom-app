import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/services/database_service.dart';
import 'package:bloom/models/cycle.dart';
import 'package:bloom/models/day_note.dart';

void main() {
  late DatabaseService db;
  late String testDbPath;

  setUp(() async {
    testDbPath = '${Directory.systemTemp.path}/test_bloom_${DateTime.now().microsecondsSinceEpoch}.json';
    DatabaseService.setCustomPath(testDbPath);
    db = DatabaseService();
  });

  tearDown(() async {
    final file = File(testDbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  group('DatabaseService CRUD & Merge Tests', () {
    test('insert and retrieve cycles', () async {
      final startDate = DateTime(2026, 8, 1);
      final id = await db.insertCycle(Cycle(startDate: startDate, periodLength: 5));
      expect(id, equals(1));

      final cycles = await db.getAllCycles();
      expect(cycles.length, equals(1));
      expect(cycles.first.periodLength, equals(5));

      final fetched = await db.getCycleById(id);
      expect(fetched, isNotNull);
      expect(fetched!.startDate.day, equals(1));
    });

    test('insert and retrieve day notes', () async {
      final date = DateTime(2026, 8, 15);
      final id = await db.insertNote(DayNote(
        date: date,
        mood: '🥰',
        flowLevel: 'Light',
        symptoms: ['Backache'],
      ));
      expect(id, equals(1));

      final note = await db.getNoteForDate(date);
      expect(note, isNotNull);
      expect(note!.mood, equals('🥰'));
      expect(note.symptoms, contains('Backache'));
    });

    test('mergeIncomingData deduplicates and updates existing records', () async {
      // Setup initial data
      final cycleDate = DateTime(2026, 7, 1);
      await db.insertCycle(Cycle(
        id: 1,
        startDate: cycleDate,
        periodLength: 4,
        updatedAt: DateTime(2026, 7, 2),
      ));

      // Incoming data with updated period length and newer updatedAt
      final incoming = {
        'cycles': [
          {
            'id': 1,
            'startDate': cycleDate.millisecondsSinceEpoch,
            'periodLength': 6,
            'createdAt': DateTime(2026, 7, 1).millisecondsSinceEpoch,
            'updatedAt': DateTime(2026, 7, 10).millisecondsSinceEpoch,
          },
          {
            'id': 2,
            'startDate': DateTime(2026, 8, 1).millisecondsSinceEpoch,
            'periodLength': 5,
            'createdAt': DateTime(2026, 8, 1).millisecondsSinceEpoch,
            'updatedAt': DateTime(2026, 8, 1).millisecondsSinceEpoch,
          }
        ],
        'notes': [
          {
            'id': 1,
            'date': DateTime(2026, 8, 1).millisecondsSinceEpoch,
            'mood': '😊',
            'content': 'Synced note',
            'crampsSeverity': 0,
            'symptoms': 'Fatigue',
            'createdAt': DateTime(2026, 8, 1).millisecondsSinceEpoch,
            'updatedAt': DateTime(2026, 8, 1).millisecondsSinceEpoch,
          }
        ]
      };

      final mergedCount = await db.mergeIncomingData(incoming);
      expect(mergedCount, equals(3)); // 1 updated cycle, 1 new cycle, 1 new note

      final cycles = await db.getAllCycles();
      expect(cycles.length, equals(2));
      final updatedCycle = cycles.firstWhere((c) => c.startDate.month == 7);
      expect(updatedCycle.periodLength, equals(6));

      final note = await db.getNoteForDate(DateTime(2026, 8, 1));
      expect(note, isNotNull);
      expect(note!.content, equals('Synced note'));
    });
  });
}
