import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/services/pdf_export_service.dart';
import 'package:bloom/models/cycle.dart';
import 'package:bloom/models/day_note.dart';

void main() {
  group('PdfExportService Tests', () {
    test('generatePeriodReport generates valid PDF byte array with cycle and note data', () async {
      final cycles = [
        Cycle(
          id: 1,
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 5),
          periodLength: 5,
          cycleLength: 28,
          notes: 'Standard cycle',
        ),
        Cycle(
          id: 2,
          startDate: DateTime(2026, 5, 29),
          endDate: DateTime(2026, 6, 3),
          periodLength: 6,
          cycleLength: 29,
          notes: 'Mild fatigue',
        ),
      ];

      final notes = [
        DayNote(
          id: 1,
          date: DateTime(2026, 5, 1),
          content: 'Started period today',
          mood: '😴',
          flowLevel: 'Medium',
          crampsSeverity: 4,
          symptoms: ['Cramps', 'Fatigue'],
        ),
      ];

      final pdfBytes = await PdfExportService.generatePeriodReport(
        cycles: cycles,
        notes: notes,
        averageCycleLength: 28,
        averagePeriodLength: 5,
        currentDay: 14,
        isOnPeriod: false,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF documents start with %PDF- header (ASCII [37, 80, 68, 70, 45])
      expect(pdfBytes.take(5).toList(), equals([37, 80, 68, 70, 45]));
    });

    test('generatePeriodReport handles empty cycle and note lists gracefully', () async {
      final pdfBytes = await PdfExportService.generatePeriodReport(
        cycles: [],
        notes: [],
        averageCycleLength: 28,
        averagePeriodLength: 5,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.take(5).toList(), equals([37, 80, 68, 70, 45]));
    });
  });
}
