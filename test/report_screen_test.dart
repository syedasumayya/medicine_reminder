import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';
import 'package:medicine_reminder/models/dose_log.dart';
import 'package:medicine_reminder/models/medicine.dart';
import 'package:medicine_reminder/screens/report_screen.dart';
import 'package:medicine_reminder/utils/time_utils.dart';

/// Makes the fake test screen tall, so the whole list is built and visible.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Report screen shows the adherence percentage', (
    WidgetTester tester,
  ) async {
    _useTallScreen(tester);
    final today = todayKey();

    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          medicines: [
            Medicine(
              id: 1,
              name: 'Panadol',
              dose: '1 tablet',
              hour: 8,
              minute: 0,
              createdOn: today,
            ),
          ],
          logs: [DoseLog(medicineId: 1, date: today, status: DoseStatus.taken)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly Report'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('1 of 1 doses taken'), findsOneWidget);
    expect(find.text('Copy report'), findsOneWidget);
    expect(find.text('Share on WhatsApp'), findsOneWidget);
  });

  testWidgets('Report screen works with no medicines', (
    WidgetTester tester,
  ) async {
    _useTallScreen(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReportScreen(medicines: [], logs: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('No doses scheduled'), findsWidgets);
  });

  testWidgets('Report button on the Home screen opens the report', (
    WidgetTester tester,
  ) async {
    _useTallScreen(tester);

    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Report'), findsOneWidget);
  });
}
