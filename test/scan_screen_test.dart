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

Future<void> _openScanScreen(WidgetTester tester) async {
  _useTallScreen(tester);
  await tester.pumpWidget(const MedicineReminderApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.document_scanner_outlined));
  await tester.pumpAndSettle();
}

/// Loads the example text and opens the Review screen.
Future<void> _openReviewWithExample(WidgetTester tester) async {
  await _openScanScreen(tester);
  await tester.tap(find.text('Load example'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Find medicines'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Scan screen opens from the Home screen',
      (WidgetTester tester) async {
    await _openScanScreen(tester);

    expect(find.text('Scan Prescription'), findsOneWidget);
    expect(find.text('Load example'), findsOneWidget);
    expect(find.text('Find medicines'), findsOneWidget);
  });

  testWidgets('Example text opens the Review screen with one row per dose',
      (WidgetTester tester) async {
    await _openReviewWithExample(tester);

    expect(find.text('Review Medicines'), findsOneWidget);
    expect(find.text('Panadol 500mg'), findsNWidgets(2)); // morning and night
    expect(find.text('Amoxil 500mg'), findsNWidgets(3)); // TDS = three times
    expect(find.text('Brufen 5ml'), findsNWidgets(2)); // BD = twice
    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('Add 8 selected'), findsOneWidget);
  });

  testWidgets('Unticking a row lowers the count', (WidgetTester tester) async {
    await _openReviewWithExample(tester);

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Add 7 selected'), findsOneWidget);
  });

  testWidgets('Text without medicines shows a helpful message',
      (WidgetTester tester) async {
    await _openScanScreen(tester);

    await tester.enterText(find.byType(TextField), 'hello world');
    await tester.tap(find.text('Find medicines'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No medicines found'), findsOneWidget);
    expect(find.text('Review Medicines'), findsNothing);
  });

  testWidgets('Adding the found medicines puts them on the Home screen',
      (WidgetTester tester) async {
    await _openReviewWithExample(tester);

    await tester.tap(find.text('Add 8 selected'));
    await tester.pumpAndSettle();

    expect(find.text('My Medicines'), findsOneWidget);
    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('Panadol 500mg'), findsNWidgets(2));
    expect(find.text('Amoxil 500mg'), findsNWidgets(3));
    expect(find.text('Brufen 5ml'), findsNWidgets(2));
  });
}
