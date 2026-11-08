import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/models/medicine.dart';
import 'package:medicine_reminder/widgets/pill_image.dart';

void main() {
  group('Medicine JSON', () {
    test('keeps the chosen icon when saved and loaded', () {
      const medicine = Medicine(
        id: 5,
        name: 'Panadol',
        dose: '1 tablet',
        hour: 8,
        minute: 30,
        createdOn: '2026-10-15',
        iconIndex: 3,
      );

      final loaded = Medicine.fromJson(medicine.toJson());

      expect(loaded.iconIndex, 3);
      expect(loaded.name, 'Panadol');
      expect(loaded.createdOn, '2026-10-15');
    });

    test('old medicines without an icon still load', () {
      final loaded = Medicine.fromJson({
        'id': 1,
        'name': 'Brufen',
        'dose': '1 dose',
        'hour': 8,
        'minute': 0,
      });

      expect(loaded.iconIndex, isNull);
      expect(loaded.createdOn, isNull);
    });

    test('no icon is written to the JSON when none was chosen', () {
      const medicine = Medicine(
        id: 1,
        name: 'Brufen',
        dose: '1 dose',
        hour: 8,
        minute: 0,
      );

      expect(medicine.toJson().containsKey('iconIndex'), false);
    });
  });

  group('Automatic pill picture', () {
    test('there are nine pictures', () {
      expect(PillImage.count, 9);
    });

    test('vitamins get the amber softgel', () {
      expect(PillImage.suggest(name: 'Vitamin D', dose: '1 tablet', seed: 4), 7);
    });

    test('capsules get a capsule picture', () {
      expect(PillImage.suggest(name: 'Amoxil', dose: '1 capsule', seed: 0), 0);
      expect(PillImage.suggest(name: 'Amoxil', dose: '1 capsule', seed: 1), 2);
      expect(PillImage.suggest(name: 'Amoxil', dose: '1 capsule', seed: 2), 4);
    });

    test('tablets get a tablet picture', () {
      expect(PillImage.suggest(name: 'Panadol', dose: '1 tablet', seed: 0), 1);
      expect(PillImage.suggest(name: 'Panadol', dose: '2 tablets', seed: 3), 6);
    });

    test('anything else gets a picture from the seed', () {
      expect(PillImage.suggest(name: 'Brufen', dose: '5 ml', seed: 10), 1);
    });

    test('a medicine with a chosen icon uses it', () {
      const medicine = Medicine(
        id: 1,
        name: 'Panadol',
        dose: '1 tablet',
        hour: 8,
        minute: 0,
        iconIndex: 8,
      );

      expect(PillImage.forMedicine(medicine), 8);
    });
  });

  testWidgets('A pill picture can be drawn', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PillBadge(index: 3, size: 80)),
      ),
    );

    expect(find.byType(PillImage), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
