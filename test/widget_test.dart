import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';
import 'package:medicine_reminder/utils/time_utils.dart';

String _oneMedicineJson() => jsonEncode([
      {'id': 1, 'name': 'Panadol', 'dose': '1 tablet', 'hour': 8, 'minute': 0}
    ]);

/// Makes the fake test screen tall, so the whole screen is built and visible.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _startApp(WidgetTester tester) async {
  _useTallScreen(tester);
  await tester.pumpWidget(const MedicineReminderApp());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Empty list shows a hint message', (WidgetTester tester) async {
    await _startApp(tester);

    expect(find.text('My Medicines'), findsOneWidget);
    expect(find.textContaining('No medicines yet'), findsOneWidget);
  });

  testWidgets('Add button opens the Add Medicine screen',
      (WidgetTester tester) async {
    await _startApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // One in the title bar and one on the button.
    expect(find.text('Add Medicine'), findsNWidgets(2));
  });

  testWidgets('Name and dose are required', (WidgetTester tester) async {
    await _startApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add Medicine'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter the medicine name'), findsOneWidget);
    expect(find.text('Please enter the dose'), findsOneWidget);
  });

  testWidgets('A new medicine appears in the list after saving',
      (WidgetTester tester) async {
    await _startApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ibuprofen');
    await tester.enterText(find.byType(TextFormField).at(1), '1 tablet');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Medicine'));
    await tester.pumpAndSettle();

    expect(find.text('Ibuprofen'), findsOneWidget);
  });

  testWidgets('Saved medicines are loaded when the app starts',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    expect(find.text('Panadol'), findsOneWidget);
    expect(find.text('0 of 1 taken today'), findsOneWidget);
  });

  testWidgets('Medicines are grouped into Morning, Afternoon and Evening',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'medicines': jsonEncode([
        {'id': 1, 'name': 'Panadol', 'dose': '1 tablet', 'hour': 8, 'minute': 0},
        {'id': 2, 'name': 'Brufen', 'dose': '1 tablet', 'hour': 14, 'minute': 0},
        {'id': 3, 'name': 'Vitamin D', 'dose': '1 capsule', 'hour': 20, 'minute': 0},
      ]),
    });
    await _startApp(tester);

    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Afternoon'), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);
  });

  testWidgets('Mark taken shows Taken and updates the progress',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    await tester.tap(find.text('Mark taken'));
    await tester.pumpAndSettle();

    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('1 of 1 taken today'), findsOneWidget);
  });

  testWidgets('Undo clears the status', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    await tester.tap(find.text('Mark taken'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Mark taken'), findsOneWidget);
    expect(find.text('0 of 1 taken today'), findsOneWidget);
  });

  testWidgets('Skip shows Skipped', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Skipped'), findsOneWidget);
  });

  testWidgets('Saved dose status is loaded when the app starts',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'medicines': _oneMedicineJson(),
      'dose_logs': jsonEncode([
        {'medicineId': 1, 'date': todayKey(), 'status': 'taken'}
      ]),
    });
    await _startApp(tester);

    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('1 of 1 taken today'), findsOneWidget);
  });

  testWidgets('Tapping a medicine opens the edit screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    await tester.tap(find.text('Panadol'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Medicine'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Delete Medicine'), findsOneWidget);
  });

  testWidgets('Editing a medicine changes its name in the list',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    await tester.tap(find.text('Panadol'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Panadol Extra');
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Panadol Extra'), findsOneWidget);
    expect(find.text('Panadol'), findsNothing);
  });

  testWidgets('Delete Medicine asks for confirmation, then removes it',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    await tester.tap(find.text('Panadol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Medicine'));
    await tester.pumpAndSettle();
    expect(find.text('Delete medicine?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Panadol'), findsNothing);
    expect(find.textContaining('No medicines yet'), findsOneWidget);
  });
}
