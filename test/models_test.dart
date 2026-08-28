import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/models/cycle.dart';
import 'package:bloom/models/day_note.dart';

void main() {
  group('Cycle Model Tests', () {
    test('Cycle toMap and fromMap serialization', () {
      final now = DateTime.now();
      final cycle = Cycle(
        id: 1,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now,
        cycleLength: 28,
        periodLength: 5,
        notes: 'Mild symptoms',
      );

      final map = cycle.toMap();
      final reconstructed = Cycle.fromMap(map);

      expect(reconstructed.id, equals(1));
      expect(reconstructed.startDate.millisecondsSinceEpoch, equals(cycle.startDate.millisecondsSinceEpoch));
      expect(reconstructed.endDate?.millisecondsSinceEpoch, equals(cycle.endDate?.millisecondsSinceEpoch));
      expect(reconstructed.cycleLength, equals(28));
      expect(reconstructed.periodLength, equals(5));
      expect(reconstructed.notes, equals('Mild symptoms'));
      expect(reconstructed.isOngoing, isFalse);
    });

    test('Cycle ongoing status and daysSinceStart', () {
      final startDate = DateTime.now().subtract(const Duration(days: 3));
      final ongoingCycle = Cycle(id: 2, startDate: startDate);

      expect(ongoingCycle.isOngoing, isTrue);
      expect(ongoingCycle.daysSinceStart, greaterThanOrEqualTo(3));
    });
  });

  group('DayNote Model Tests', () {
    test('DayNote toMap and fromMap serialization with symptoms list', () {
      final date = DateTime(2026, 8, 28);
      final note = DayNote(
        id: 10,
        date: date,
        mood: '😊',
        flowLevel: 'Medium',
        crampsSeverity: 4,
        symptoms: ['Headache', 'Bloating', 'Fatigue'],
        content: 'Feeling energized in the afternoon',
      );

      final map = note.toMap();
      final reconstructed = DayNote.fromMap(map);

      expect(reconstructed.id, equals(10));
      expect(reconstructed.date.year, equals(2026));
      expect(reconstructed.date.month, equals(8));
      expect(reconstructed.date.day, equals(28));
      expect(reconstructed.mood, equals('😊'));
      expect(reconstructed.flowLevel, equals('Medium'));
      expect(reconstructed.crampsSeverity, equals(4));
      expect(reconstructed.symptoms, equals(['Headache', 'Bloating', 'Fatigue']));
      expect(reconstructed.content, equals('Feeling energized in the afternoon'));
    });

    test('DayNote copyWith updates fields correctly', () {
      final date = DateTime(2026, 8, 28);
      final note = DayNote(date: date, mood: '😐', crampsSeverity: 2);
      final updated = note.copyWith(mood: '🥰', crampsSeverity: 0);

      expect(updated.mood, equals('🥰'));
      expect(updated.crampsSeverity, equals(0));
      expect(updated.date, equals(date));
    });
  });
}
