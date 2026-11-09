import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';
import 'package:medicine_reminder/models/medicine.dart';
import 'package:medicine_reminder/screens/reminder_settings_screen.dart';
import 'package:medicine_reminder/services/reminder_service.dart';

/// Makes the fake test screen tall, so the whole screen is built and visible.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const Medicine _evening = Medicine(
  id: 2,
  name: 'Vitamin D',
  dose: '1 capsule',
  hour: 21,
  minute: 0,
);

void main() {
  late List<http.Request> requests;
  late ReminderService service;

  Future<void> openSettings(
    WidgetTester tester, {
    List<Medicine> medicines = const [],
  }) async {
    _useTallScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderSettingsScreen(
          medicines: medicines,
          logs: const [],
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'reminder_topic': 'medrem-testtopic',
    });
    requests = [];
    service = ReminderService(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      }),
      // 12:00 noon, so a 21:00 dose is still ahead today.
      clock: () => DateTime(2026, 10, 15, 12, 0),
    );
  });

  testWidgets('shows the secret topic and the set-up steps',
      (WidgetTester tester) async {
    await openSettings(tester);

    expect(find.text('Phone Reminders'), findsOneWidget);
    expect(find.text('medrem-testtopic'), findsOneWidget);
    expect(find.text('Set up (one time)'), findsOneWidget);
    expect(find.text('Send test notification'), findsOneWidget);
  });

  testWidgets('the test button sends one scheduled message',
      (WidgetTester tester) async {
    await openSettings(tester);

    await tester.tap(find.text('Send test notification'));
    await tester.pumpAndSettle();

    expect(requests.length, 1);
    expect(requests.single.headers['X-Sequence-ID'], 'test');
    expect(find.textContaining('Test sent'), findsOneWidget);
  });

  testWidgets('turning reminders on schedules the coming doses and saves',
      (WidgetTester tester) async {
    await openSettings(tester, medicines: [_evening]);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // 21:00 today, tomorrow and the day after
    expect(requests.length, 3);
    expect(find.textContaining('Phone reminders are on'), findsOneWidget);
    expect(find.textContaining('3 reminder(s) scheduled'), findsOneWidget);

    final saved = await service.loadSettings();
    expect(saved.enabled, isTrue);
  });

  testWidgets('turning reminders on with no medicines sends nothing',
      (WidgetTester tester) async {
    await openSettings(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(requests, isEmpty);
    expect(find.textContaining('No reminders are needed right now'),
        findsOneWidget);
  });

  testWidgets('turning reminders off says so', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'reminder_topic': 'medrem-testtopic',
      'reminder_enabled': true,
    });
    await openSettings(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Phone reminders are off.'), findsOneWidget);
    final saved = await service.loadSettings();
    expect(saved.enabled, isFalse);
  });

  testWidgets('Home shows a banner while reminders are off and opens the setup',
      (WidgetTester tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    expect(find.text('Get reminders on your phone'), findsOneWidget);

    await tester.tap(find.text('Get reminders on your phone'));
    await tester.pumpAndSettle();

    expect(find.text('Phone Reminders'), findsOneWidget);
  });

  testWidgets('the banner is gone once reminders are on',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'reminder_topic': 'medrem-testtopic',
      'reminder_enabled': true,
    });
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    expect(find.text('Get reminders on your phone'), findsNothing);
  });

  testWidgets('the bell in the bottom bar opens the reminders setup',
      (WidgetTester tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Phone Reminders'), findsOneWidget);
  });
}
