import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/services/prescription_parser.dart';

void main() {
  test('reads name, strength, dose and morning/night pattern', () {
    final result = PrescriptionParser.parse('Tab Panadol 500mg 1+0+1 x 5 days');

    expect(result.length, 1);
    expect(result[0].name, 'Panadol 500mg');
    expect(result[0].dose, '1 tablet');
    expect(result[0].hours, [8, 21]);
    expect(result[0].timesGuessed, false);
  });

  test('reads TDS as three times a day', () {
    final result = PrescriptionParser.parse('Cap. Amoxil 500mg TDS x 7 days');

    expect(result[0].name, 'Amoxil 500mg');
    expect(result[0].dose, '1 capsule');
    expect(result[0].hours, [8, 14, 21]);
  });

  test('reads BD as twice a day', () {
    final result = PrescriptionParser.parse('Syp Brufen 5ml BD');

    expect(result[0].name, 'Brufen 5ml');
    expect(result[0].dose, '1 dose');
    expect(result[0].hours, [8, 20]);
  });

  test('uses a plural dose when the amount is more than one', () {
    final result = PrescriptionParser.parse('Tab Disprin 2+0+2');

    expect(result[0].name, 'Disprin');
    expect(result[0].dose, '2 tablets');
    expect(result[0].hours, [8, 21]);
  });

  test('guesses 8 AM when the text has no timing', () {
    final result = PrescriptionParser.parse('Tab Vitamin D');

    expect(result[0].name, 'Vitamin D');
    expect(result[0].hours, [8]);
    expect(result[0].timesGuessed, true);
  });

  test('handles numbered lines and ignores lines that are not medicines', () {
    const text = '''Dr. Ahmed Khan
Date: 15-10-2026
1) Tab Panadol 500mg 1+0+1 x 5 days
2) Cap. Amoxil 500mg TDS x 7 days
3) Syp Brufen 5ml BD
4) Tab Vitamin D''';

    final names = PrescriptionParser.parse(text).map((m) => m.name).toList();

    expect(names, ['Panadol 500mg', 'Amoxil 500mg', 'Brufen 5ml', 'Vitamin D']);
  });

  test('empty text gives an empty list', () {
    expect(PrescriptionParser.parse(''), isEmpty);
  });
}
