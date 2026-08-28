import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom/services/bloom_provider.dart';
import 'package:bloom/services/database_service.dart';
import 'package:bloom/models/cycle.dart';

void main() {
  late String testDbPath;
  late BloomProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'bloom_device_id': 'testdevice123',
      'bloom_pairing_code': 'K8Y4B2',
      'bloom_server_url': 'ws://localhost:3000',
    });
    testDbPath = '${Directory.systemTemp.path}/test_bloom_provider_${DateTime.now().microsecondsSinceEpoch}.json';
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

  group('BloomProvider Calculations', () {
    test('Calculates rolling cycle average and period lengths correctly', () async {
      expect(provider.averageCycleLength, equals(28));
      expect(provider.averagePeriodLength, equals(5));

      // Add cycles: 28 days apart
      final now = DateTime.now();
      await DatabaseService().insertCycle(Cycle(
        id: 1,
        startDate: now.subtract(const Duration(days: 56)),
        endDate: now.subtract(const Duration(days: 51)),
        periodLength: 5,
      ));
      await DatabaseService().insertCycle(Cycle(
        id: 2,
        startDate: now.subtract(const Duration(days: 28)),
        endDate: now.subtract(const Duration(days: 23)),
        periodLength: 5,
      ));

      await provider.loadData();

      expect(provider.totalCycles, equals(2));
      expect(provider.averageCycleLength, equals(28));
      expect(provider.predictedNextStart, isNotNull);
    });

    test('startPeriod and endPeriod state transitions', () async {
      expect(provider.latestCycle, isNull);

      await provider.startPeriod();
      expect(provider.latestCycle, isNotNull);
      expect(provider.latestCycle!.isOngoing, isTrue);
      expect(provider.isOnPeriod, isTrue);

      await provider.endPeriod();
      expect(provider.latestCycle!.isOngoing, isFalse);
      expect(provider.latestCycle!.periodLength, isNotNull);
    });
  });
}
