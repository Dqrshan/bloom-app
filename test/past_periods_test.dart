import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom/services/bloom_provider.dart';
import 'package:bloom/services/database_service.dart';

void main() {
  late String testDbPath;
  late BloomProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'bloom_device_id': 'testdevice123',
      'bloom_pairing_code': 'K8Y4B2',
      'bloom_server_url': 'ws://localhost:3000',
      'bloom_ai_api_key': 'mock_ai_test_key',
    });
    testDbPath = '${Directory.systemTemp.path}/test_bloom_past_periods_${DateTime.now().microsecondsSinceEpoch}.json';
    DatabaseService.setCustomPath(testDbPath);
    provider = BloomProvider();
    await provider.loadData();
  });

  tearDown(() async {
    final file = File(testDbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  group('Past Period Logging Tests', () {
    test('startPeriod called multiple times today does not create duplicate cycles', () async {
      await provider.startPeriod();
      expect(provider.totalCycles, equals(1));

      // Call startPeriod again on the same day
      await provider.startPeriod();
      expect(provider.totalCycles, equals(1));

      // Call startPeriodForDate again for today
      await provider.startPeriodForDate(DateTime.now());
      expect(provider.totalCycles, equals(1));
    });

    test('logPastPeriod for the same start date updates existing cycle without duplicating', () async {
      final date = DateTime(2026, 7, 10);
      await provider.logPastPeriod(
        startDate: date,
        periodLength: 4,
        notes: 'First log',
      );
      expect(provider.totalCycles, equals(1));
      expect(provider.cycles.first.periodLength, equals(4));

      // Log again on the exact same date with updated duration
      await provider.logPastPeriod(
        startDate: date,
        periodLength: 6,
        notes: 'Updated log',
      );
      expect(provider.totalCycles, equals(1));
      expect(provider.cycles.first.periodLength, equals(6));
      expect(provider.cycles.first.notes, equals('Updated log'));
    });

    test('logPastPeriod adds past cycle with specified dates and length', () async {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 6, 5);

      await provider.logPastPeriod(
        startDate: start,
        endDate: end,
        periodLength: 5,
        notes: 'Past period recorded',
      );

      final cycles = provider.cycles;
      expect(cycles.length, equals(1));
      expect(cycles.first.startDate.month, equals(6));
      expect(cycles.first.startDate.day, equals(1));
      expect(cycles.first.periodLength, equals(5));
      expect(cycles.first.isOngoing, isFalse);
    });

    test('logPastPeriod with multiple historic cycles updates average cycle and period math', () async {
      await provider.logPastPeriod(
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 5),
        periodLength: 5,
      );

      await provider.logPastPeriod(
        startDate: DateTime(2026, 5, 29),
        endDate: DateTime(2026, 6, 2),
        periodLength: 5,
      );

      await provider.logPastPeriod(
        startDate: DateTime(2026, 6, 26),
        endDate: DateTime(2026, 6, 30),
        periodLength: 5,
      );

      expect(provider.totalCycles, equals(3));
      expect(provider.averageCycleLength, equals(28));
      expect(provider.averagePeriodLength, equals(5));
    });

    test('deleteCycle removes cycle and updates provider state', () async {
      await provider.logPastPeriod(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 5),
        periodLength: 5,
      );

      expect(provider.totalCycles, equals(1));
      final id = provider.cycles.first.id!;

      await provider.deleteCycle(id);
      expect(provider.totalCycles, equals(0));
    });
  });
}
