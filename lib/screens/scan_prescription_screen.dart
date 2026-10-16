import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/prescription_parser.dart';

class ScanPrescriptionScreen extends StatefulWidget {
  const ScanPrescriptionScreen({super.key});

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
  List<ParsedMedicine> _results = [];
  List<bool> _selected = [];
  bool _searched = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _loadExample() {
    setState(() {
      _textController.text = _exampleText;
    });
  }

  void _findMedicines() {
    final found = PrescriptionParser.parse(_textController.text);
    setState(() {
      _results = found;
      _selected = List<bool>.filled(found.length, true);
      _searched = true;
    });
  }

  void _addSelected() {
    final baseId = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final medicines = <Medicine>[];
    var counter = 0;
    for (var i = 0; i < _results.length; i++) {
      if (!_selected[i]) continue;
      for (final hour in _results[i].hours) {
        medicines.add(
          Medicine(
            id: baseId + counter,
            name: _results[i].name,
            dose: _results[i].dose,
            hour: hour,
            minute: 0,
          ),
        );
        counter++;
      }
    }
    Navigator.pop(context, medicines);
  }

  String _describe(ParsedMedicine medicine) {
    final times = medicine.hours
        .map((h) => TimeOfDay(hour: h, minute: 0).format(context))
        .join(', ');
    final note = medicine.timesGuessed ? '  (time guessed, please check)' : '';
    return '${medicine.dose} at $times$note';
  }

  List<Widget> _buildResults() {
    if (!_searched) return [];

    if (_results.isEmpty) {
      return [
        const Text(
          'No medicines found. Put each medicine on its own line, starting '
          'with Tab, Cap, Syp, Inj, Drops, Oint or Cream.',
        ),
      ];
    }

    final selectedCount = _selected.where((s) => s).length;
    return [
      Text(
        'Found ${_results.length} medicine(s). Untick any you do not want.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      for (var i = 0; i < _results.length; i++)
        CheckboxListTile(
          value: _selected[i],
          onChanged: (value) {
            setState(() {
              _selected[i] = value ?? false;
            });
          },
          title: Text(_results[i].name),
          subtitle: Text(_describe(_results[i])),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: selectedCount == 0 ? null : _addSelected,
        child: Text('Add $selectedCount selected'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Prescription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Camera scanning comes later (Phase 5b, on Android). For now, '
                'type or paste the text of a prescription below, one medicine '
                'per line.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Prescription text',
              hintText: 'Tab Panadol 500mg 1+0+1 x 5 days',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: _loadExample,
                child: const Text('Load example'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _findMedicines,
                  child: const Text('Find medicines'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildResults(),
        ],
      ),
    );
  }
}
