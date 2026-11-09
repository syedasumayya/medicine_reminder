import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Reads the text inside a PDF file.
///
/// This only works for PDFs that contain real text (for example a prescription
/// made on a computer). A photo or a scan saved as a PDF has no text inside,
/// so nothing can be read from it.
class PdfTextReader {
  /// Gives back all the text of the PDF, tidied up.
  /// Throws an error if the bytes are not a valid PDF.
  static String extractText(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final text = PdfTextExtractor(document).extractText();
      return clean(text);
    } finally {
      document.dispose();
    }
  }

  /// Tidies text that came out of a PDF: one line per row, no empty lines,
  /// no double spaces.
  static String clean(String text) {
    final lines = text
        .replaceAll('\u00A0', ' ')
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .where((line) => line.isNotEmpty);
    return lines.join('\n');
  }
}
