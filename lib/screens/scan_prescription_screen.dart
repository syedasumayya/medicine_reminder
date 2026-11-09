import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/pdf_import.dart';
import '../services/prescription_parser.dart';
import 'review_medicines_screen.dart';

/// The screen where a prescription is imported: the user uploads a PDF
/// (or pastes the text), then presses Find medicines.
class ScanPrescriptionScreen extends StatefulWidget {
  /// How a PDF is picked and read. The tests give a fake one.
  final Future<PdfImportResult?> Function() pickPdf;

  const ScanPrescriptionScreen({super.key, this.pickPdf = pickAndReadPdf});

  @override
  State<ScanPrescriptionScreen> createState() => _ScanPrescriptionScreenState();
}

class _ScanPrescriptionScreenState extends State<ScanPrescriptionScreen> {
  static const String _exampleText = '''Dr. Ahmed Khan
Date: 15-10-2026
1) Tab Panadol 500mg 1+0+1 x 5 days
2) Cap. Amoxil 500mg TDS x 7 days
3) Syp Brufen 5ml BD
4) Tab Vitamin D''';

  final _textController = TextEditingController();
  bool _noResults = false;
  bool _reading = false;
  String? _pdfMessage;
  bool _pdfMessageIsError = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _loadExample() {
    setState(() {
      _textController.text = _exampleText;
      _noResults = false;
      _pdfMessage = null;
    });
  }

  Future<void> _uploadPdf() async {
    setState(() {
      _reading = true;
      _pdfMessage = null;
      _noResults = false;
    });

    PdfImportResult? result;
    var pickerFailed = false;
    try {
      result = await widget.pickPdf();
    } catch (_) {
      pickerFailed = true;
    }
    if (!mounted) return;

    if (pickerFailed) {
      setState(() {
        _reading = false;
        _pdfMessage = 'Something went wrong while opening the file picker.';
        _pdfMessageIsError = true;
      });
      return;
    }

    // The user closed the picker without choosing a file.
    if (result == null) {
      setState(() {
        _reading = false;
      });
      return;
    }

    final picked = result;
    setState(() {
      _reading = false;
      if (picked.failed) {
        _pdfMessage = '${picked.fileName} could not be read. '
            'Please check that it is a real PDF file.';
        _pdfMessageIsError = true;
      } else if (picked.text.trim().isEmpty) {
        _pdfMessage = 'No text was found in ${picked.fileName}. It may be a '
            'photo or a scan. Please paste the text instead.';
        _pdfMessageIsError = true;
      } else {
        _textController.text = picked.text;
        _pdfMessage = 'Read ${picked.fileName}. Check the text below, then '
            'press Find medicines.';
        _pdfMessageIsError = false;
      }
    });
  }

  Future<void> _findMedicines() async {
    final found = PrescriptionParser.parse(_textController.text);
    if (found.isEmpty) {
      setState(() {
        _noResults = true;
      });
      return;
    }
    setState(() {
      _noResults = false;
    });

    final result = await Navigator.push<List<Medicine>>(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewMedicinesScreen(parsed: found),
      ),
    );
    if (result == null || !mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Import Prescription',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          FilledButton.icon(
            onPressed: _reading ? null : _uploadPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_reading ? 'Reading PDF...' : 'Upload PDF'),
          ),
          if (_pdfMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pdfMessageIsError
                    ? scheme.errorContainer
                    : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _pdfMessage!,
                style: TextStyle(
                  color: _pdfMessageIsError
                      ? scheme.onErrorContainer
                      : scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            minLines: 7,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: 'Or paste the prescription text here, for example:\n'
                  'Tab Panadol 500mg 1+0+1 x 5 days',
              filled: true,
              fillColor: scheme.surface,
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: _loadExample,
            icon: const Icon(Icons.description_outlined),
            label: const Text('Load example'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _findMedicines,
            icon: const Icon(Icons.search),
            label: const Text('Find medicines'),
          ),
          if (_noResults) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No medicines found. Put each medicine on its own line, '
                'starting with Tab, Cap, Syp, Inj, Drops, Oint or Cream.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Upload a PDF that contains text (a typed prescription). '
                    'A photo or a scan saved as PDF cannot be read. Only lines '
                    'starting with Tab, Tablet, Cap, Capsule, Syp, Syrup, Inj, '
                    'Injection, Drops, Oint, Ointment or Cream are used.',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
