import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';
import 'package:medicine_reminder/utils/time_utils.dart';

String _oneMedicineJson() => jsonEncode([
  {'id': 1, 'name': 'Panadol', 'dose': '1 tablet', 'hour': 8, 'minute': 0},
]);

Future<void> _startApp(WidgetTester tester) async {
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

  testWidgets('Add button opens the Add Medicine screen', (
    WidgetTester tester,
  ) async {
    await _startApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Medicine'), findsOneWidget);
  });

  testWidgets('A new medicine appears in the list after saving', (
    WidgetTester tester,
  ) async {
    await _startApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ibuprofen');
    await tester.enterText(find.byType(TextFormField).at(1), '1 tablet');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Ibuprofen'), findsOneWidget);
  });

  testWidgets('Saved medicines are loaded when the app starts', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    expect(find.text('Panadol'), findsOneWidget);
    expect(find.text('0 of 1 taken today'), findsOneWidget);
  });

  testWidgets('Mark taken shows Taken and updates the progress', (
    WidgetTester tester,
  ) async {
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

  testWidgets('Saved dose status is loaded when the app starts', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'medicines': _oneMedicineJson(),
      'dose_logs': jsonEncode([
        {'medicineId': 1, 'date': todayKey(), 'status': 'taken'},
      ]),
    });
    await _startApp(tester);

    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('1 of 1 taken today'), findsOneWidget);
  });

  testWidgets('Tapping a medicine opens the edit screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    await tester.tap(find.text('Panadol'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Medicine'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('Delete asks for confirmation, then removes the medicine', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'medicines': _oneMedicineJson()});
    await _startApp(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete medicine?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Panadol'), findsNothing);
  });
}
