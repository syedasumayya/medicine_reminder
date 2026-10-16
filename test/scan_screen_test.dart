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

Future<void> _openScanScreen(WidgetTester tester) async {
  _useTallScreen(tester);
  await tester.pumpWidget(const MedicineReminderApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.document_scanner_outlined));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Scan screen opens from the Home screen', (
    WidgetTester tester,
  ) async {
    await _openScanScreen(tester);

    expect(find.text('Scan Prescription'), findsOneWidget);
  });

  testWidgets('Example text shows the medicines that were found', (
    WidgetTester tester,
  ) async {
    await _openScanScreen(tester);

    await tester.tap(find.text('Load example'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find medicines'));
    await tester.pumpAndSettle();

    expect(find.text('Panadol 500mg'), findsOneWidget);
    expect(find.text('Amoxil 500mg'), findsOneWidget);
    expect(find.text('Add 4 selected'), findsOneWidget);
  });

  testWidgets('Text without medicines shows a helpful message', (
    WidgetTester tester,
  ) async {
    await _openScanScreen(tester);

    await tester.enterText(find.byType(TextField), 'hello world');
    await tester.tap(find.text('Find medicines'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No medicines found'), findsOneWidget);
  });

  testWidgets('Adding the found medicines puts them on the Home screen', (
    WidgetTester tester,
  ) async {
    await _openScanScreen(tester);

    await tester.tap(find.text('Load example'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find medicines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 4 selected'));
    await tester.pumpAndSettle();

    expect(find.text('My Medicines'), findsOneWidget);
    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('Panadol 500mg'), findsNWidgets(2)); // morning and night
    expect(find.text('Amoxil 500mg'), findsNWidgets(3)); // TDS = three times
  });
}
