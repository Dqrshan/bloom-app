import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom/main.dart';
import 'package:bloom/services/database_service.dart';
import 'package:bloom/services/sync_service.dart';

void main() {
  late String testDbPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'bloom_device_id': 'testdevice123',
      'bloom_pairing_code': 'K8Y4B2',
      'bloom_server_url': 'ws://localhost:3000',
    });
    testDbPath = '${Directory.systemTemp.path}/test_bloom_widget_${DateTime.now().microsecondsSinceEpoch}.json';
    DatabaseService.setCustomPath(testDbPath);
  });

  tearDown(() async {
    SyncService().disconnect();
    final file = File(testDbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  testWidgets('App renders clean tabs and navigates smoothly', (WidgetTester tester) async {
    await tester.pumpWidget(const BloomApp());
    await tester.pumpAndSettle();

    // Verify Home tab has clean time greeting and log period button
    expect(find.text('Log Period'), findsOneWidget);
    expect(find.text('Daily Note'), findsOneWidget);

    // Tap Calendar tab
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Fertile'), findsOneWidget);
    expect(find.text('Period'), findsWidgets);

    // Tap Notes tab
    await tester.tap(find.byIcon(Icons.edit_note_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Daily Notes'), findsOneWidget);

    // Tap Sync tab
    await tester.tap(find.byIcon(Icons.sync_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Partner Sync'), findsOneWidget);
    expect(find.text('My Pairing Code'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('DATA MANAGEMENT'), findsOneWidget);
    expect(find.text('Export PDF Health Report'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('PRIVACY & SECURITY'), findsOneWidget);

    // Clean up active connections and timers
    SyncService().disconnect();
    await tester.pumpAndSettle();
  });
}
