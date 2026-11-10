import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';
import 'package:medicine_reminder/widgets/app_logo.dart';
import 'package:medicine_reminder/screens/scan_prescription_screen.dart';
import 'package:medicine_reminder/services/pdf_import.dart';

const String _exampleText = '''Dr. Ahmed Khan
Date: 15-10-2026
1) Tab Panadol 500mg 1+0+1 x 5 days
2) Cap. Amoxil 500mg TDS x 7 days
3) Syp Brufen 5ml BD
4) Tab Vitamin D''';

/// Makes the fake test screen tall, so the whole screen is built and visible.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openImportScreen(WidgetTester tester) async {
  _useTallScreen(tester);
  await tester.pumpWidget(const MedicineReminderApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.upload_file_outlined));
  await tester.pumpAndSettle();
}

/// Opens the import screen on its own, with a fake PDF picker.
Future<void> _openImportWithPicker(
  WidgetTester tester,
  Future<PdfImportResult?> Function() pickPdf,
) async {
  _useTallScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: ScanPrescriptionScreen(pickPdf: pickPdf)),
  );
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).controller!.text;
}

/// Loads the example text and opens the Review screen.
Future<void> _openReviewWithExample(WidgetTester tester) async {
  await _openImportScreen(tester);
  await tester.tap(find.text('Load example'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Find medicines'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Import screen opens from the Home screen',
      (WidgetTester tester) async {
    await _openImportScreen(tester);

    expect(find.text('Import Prescription'), findsOneWidget);
    expect(find.text('Upload PDF'), findsOneWidget);
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
    await _openImportScreen(tester);

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

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('Panadol 500mg'), findsNWidgets(2));
    expect(find.text('Amoxil 500mg'), findsNWidgets(3));
    expect(find.text('Brufen 5ml'), findsNWidgets(2));
  });

  group('Upload PDF', () {
    testWidgets('puts the text of the PDF into the text box',
        (WidgetTester tester) async {
      await _openImportWithPicker(
        tester,
        () async => const PdfImportResult(
          fileName: 'rx.pdf',
          text: 'Tab Panadol 500mg 1+0+1 x 5 days',
        ),
      );

      await tester.tap(find.text('Upload PDF'));
      await tester.pumpAndSettle();

      expect(_fieldText(tester), contains('Panadol'));
      expect(find.textContaining('Read rx.pdf'), findsOneWidget);
    });

    testWidgets('then Find medicines opens the Review screen',
        (WidgetTester tester) async {
      await _openImportWithPicker(
        tester,
        () async => const PdfImportResult(
          fileName: 'rx.pdf',
          text: _exampleText,
        ),
      );

      await tester.tap(find.text('Upload PDF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find medicines'));
      await tester.pumpAndSettle();

      expect(find.text('Review Medicines'), findsOneWidget);
      expect(find.text('Add 8 selected'), findsOneWidget);
    });

    testWidgets('a PDF without text asks the user to paste the text',
        (WidgetTester tester) async {
      await _openImportWithPicker(
        tester,
        () async => const PdfImportResult(fileName: 'scan.pdf', text: ''),
      );

      await tester.tap(find.text('Upload PDF'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No text was found in scan.pdf'),
          findsOneWidget);
      expect(_fieldText(tester), isEmpty);
    });

    testWidgets('a broken file shows an error message',
        (WidgetTester tester) async {
      await _openImportWithPicker(
        tester,
        () async => const PdfImportResult(fileName: 'bad.pdf', failed: true),
      );

      await tester.tap(find.text('Upload PDF'));
      await tester.pumpAndSettle();

      expect(find.textContaining('bad.pdf could not be read'), findsOneWidget);
    });

    testWidgets('closing the picker changes nothing',
        (WidgetTester tester) async {
      await _openImportWithPicker(tester, () async => null);

      await tester.tap(find.text('Upload PDF'));
      await tester.pumpAndSettle();

      expect(_fieldText(tester), isEmpty);
      expect(find.textContaining('Read '), findsNothing);
      expect(find.textContaining('No text was found'), findsNothing);
    });

    testWidgets('an error in the picker is shown and does not crash',
        (WidgetTester tester) async {
      await _openImportWithPicker(
        tester,
        () async => throw Exception('picker failed'),
      );

      await tester.tap(find.text('Upload PDF'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
      expect(find.text('Upload PDF'), findsOneWidget);
    });
  });
}
