import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Empty list shows a hint message', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    expect(find.text('My Medicines'), findsOneWidget);
    expect(find.textContaining('No medicines yet'), findsOneWidget);
  });

  testWidgets('Add button opens the Add Medicine screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Medicine'), findsOneWidget);
  });

  testWidgets('A new medicine appears in the list after saving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

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
    SharedPreferences.setMockInitialValues({
      'medicines': jsonEncode([
        {
          'id': 1,
          'name': 'Panadol',
          'dose': '1 tablet',
          'hour': 8,
          'minute': 0,
        },
      ]),
    });

    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    expect(find.text('Panadol'), findsOneWidget);
  });

  testWidgets('Delete button removes a medicine', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'medicines': jsonEncode([
        {
          'id': 1,
          'name': 'Panadol',
          'dose': '1 tablet',
          'hour': 8,
          'minute': 0,
        },
      ]),
    });

    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Panadol'), findsNothing);
  });
}
