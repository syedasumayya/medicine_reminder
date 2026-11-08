import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';

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

  testWidgets('About dialog shows the medical disclaimer', (
    WidgetTester tester,
  ) async {
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('not a substitute for medical advice'),
      findsOneWidget,
    );
  });

  testWidgets('Scan results remind the user to check the prescription', (
    WidgetTester tester,
  ) async {
    _useTallScreen(tester);
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
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
