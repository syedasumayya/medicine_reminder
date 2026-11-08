import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/prescription_parser.dart';
import '../utils/time_utils.dart';
import '../widgets/pill_image.dart';

/// One row on the review screen: one medicine at one time of day.
class _ReviewEntry {
  final ParsedMedicine source;
  final int sourceIndex;
  final int hour;

  const _ReviewEntry(this.source, this.sourceIndex, this.hour);
}

/// Shows the medicines found in a prescription so the user can check them
/// (and untick the ones they do not want) before they are added.
/// It gives back the list of Medicine objects to add, or null if the user
/// goes back.
class ReviewMedicinesScreen extends StatefulWidget {
  final List<ParsedMedicine> parsed;

  const ReviewMedicinesScreen({super.key, required this.parsed});

  @override
  State<ReviewMedicinesScreen> createState() => _ReviewMedicinesScreenState();
}

class _ReviewMedicinesScreenState extends State<ReviewMedicinesScreen> {
  late final List<_ReviewEntry> _entries;
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _entries = [
      for (var i = 0; i < widget.parsed.length; i++)
        for (final hour in widget.parsed[i].hours)
          _ReviewEntry(widget.parsed[i], i, hour),
    ];
    _selected = List<bool>.filled(_entries.length, true);
  }

  int get _selectedCount => _selected.where((s) => s).length;

  void _addSelected() {
    final baseId = DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    final today = todayKey();
    final medicines = <Medicine>[];

    for (var i = 0; i < _entries.length; i++) {
      if (!_selected[i]) continue;
      final entry = _entries[i];
      medicines.add(
        Medicine(
          id: baseId + i,
          name: entry.source.name,
          dose: entry.source.dose,
          hour: entry.hour,
          minute: 0,
          createdOn: today,
          // Same medicine at different times gets the same picture.
          iconIndex: PillImage.suggest(
            name: entry.source.name,
            dose: entry.source.dose,
            seed: entry.sourceIndex,
          ),
        ),
      );
    }
    Navigator.pop(context, medicines);
  }

  Widget _buildRow(int i) {
    final scheme = Theme.of(context).colorScheme;
    final entry = _entries[i];
    final time = TimeOfDay(hour: entry.hour, minute: 0).format(context);
    final note = entry.source.timesGuessed ? '  (time guessed, please check)' : '';

    return Card(
      elevation: 0,
      color: scheme.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        value: _selected[i],
        onChanged: (value) {
          setState(() {
            _selected[i] = value ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          entry.source.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${entry.source.dose}  •  $time$note'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = _selectedCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Review Medicines',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
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
                    'Always check these against your real prescription '
                    'before adding.',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _entries.length; i++) _buildRow(i),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: count == 0 ? null : _addSelected,
            child: Text('Add $count selected'),
          ),
        ),
      ),
    );
  }
}
