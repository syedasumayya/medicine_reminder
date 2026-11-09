import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';

/// Makes the fake test screen tall, so the whole screen is built and visible.
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

  testWidgets('About page shows the medical disclaimer',
      (WidgetTester tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('Medicine Reminder'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(
      find.textContaining('not a substitute for medical advice'),
      findsOneWidget,
    );
  });

  testWidgets('The bottom bar opens the About page too',
      (WidgetTester tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('not a substitute for medical advice'),
      findsOneWidget,
    );
  });

  testWidgets('The bottom bar opens the weekly report',
      (WidgetTester tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Report'), findsOneWidget);
  });

  testWidgets('Review screen reminds the user to check the prescription',
      (WidgetTester tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.upload_file_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load example'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find medicines'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('check these against your real prescription'),
      findsOneWidget,
    );
  });
}
