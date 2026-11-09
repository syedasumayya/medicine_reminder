import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/services/pdf_text_reader.dart';

void main() {
  test('clean puts one line per row and removes extra spaces', () {
    const messy = '  Tab Panadol   500mg \r\n\r\n 1+0+1\u00A0x 5 days\r\n\r\n';

    expect(PdfTextReader.clean(messy), 'Tab Panadol 500mg\n1+0+1 x 5 days');
  });

  test('clean gives an empty text when there is nothing to read', () {
    expect(PdfTextReader.clean('  \r\n \n'), '');
  });

  test('clean keeps normal text as it is', () {
    const text = '1) Tab Panadol 500mg 1+0+1 x 5 days\n2) Syp Brufen 5ml BD';

    expect(PdfTextReader.clean(text), text);
  });
}
