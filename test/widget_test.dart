import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/main.dart';

void main() {
  testWidgets('Home screen shows the medicine list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MedicineReminderApp());

    expect(find.text('My Medicines'), findsOneWidget);
    expect(find.text('Panadol'), findsOneWidget);
  });

  testWidgets('Add button opens the Add Medicine screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MedicineReminderApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Medicine'), findsOneWidget);
  });

  testWidgets('A new medicine appears in the list after saving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MedicineReminderApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ibuprofen');
    await tester.enterText(find.byType(TextFormField).at(1), '1 tablet');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Ibuprofen'), findsOneWidget);
  });
}
