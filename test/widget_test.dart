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
}
