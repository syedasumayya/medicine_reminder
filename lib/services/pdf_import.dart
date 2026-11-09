import 'package:file_picker/file_picker.dart';
import 'pdf_text_reader.dart';

/// The result of picking a PDF and trying to read it.
class PdfImportResult {
  /// The name of the picked file, like prescription.pdf
  final String fileName;

  /// The text found inside the PDF (empty if there was none).
  final String text;

  /// True if the file could not be opened as a PDF at all.
  final bool failed;

  const PdfImportResult({
    required this.fileName,
    this.text = '',
    this.failed = false,
  });
}

/// Opens the file picker (only PDF files), then reads the text of the PDF.
/// Gives back null if the user closed the picker without choosing a file.
Future<PdfImportResult?> pickAndReadPdf() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (files.isEmpty) return null;

  final file = files.first;
  try {
    final bytes = await file.readAsBytes();
    final text = PdfTextReader.extractText(bytes);
    return PdfImportResult(fileName: file.name, text: text);
  } catch (_) {
    return PdfImportResult(fileName: file.name, failed: true);
  }
}
