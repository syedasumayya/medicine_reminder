import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/pill_image.dart';

/// What the form gives back to the Home screen:
/// either a saved medicine, or "the user deleted this medicine".
class MedicineFormResult {
  final Medicine? medicine;
  final bool deleted;

  const MedicineFormResult.saved(this.medicine) : deleted = false;

  const MedicineFormResult.removed()
      : medicine = null,
        deleted = true;
}

class AddMedicineScreen extends StatefulWidget {
  /// If this is given, the screen edits that medicine instead of adding one.
  final Medicine? existing;

  const AddMedicineScreen({super.key, this.existing});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late TimeOfDay _selectedTime;
  late final int _medicineId;
  int? _chosenIcon;

  bool get _isEditing => widget.existing != null;

  /// The pill picture: the one the user chose, or an automatic one that
  /// follows what they type (capsule, tablet, vitamin ...).
  int get _iconIndex =>
      _chosenIcon ??
      PillImage.suggest(
        name: _nameController.text,
        dose: _doseController.text,
        seed: _medicineId,
      );

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _medicineId =
        existing?.id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000000);
    _chosenIcon = existing?.iconIndex;
    _nameController = TextEditingController(text: existing?.name ?? '')
      ..addListener(_refresh);
    _doseController = TextEditingController(text: existing?.dose ?? '')
      ..addListener(_refresh);
    _selectedTime = existing == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(hour: existing.hour, minute: existing.minute);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _chooseIcon() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _IconPicker(selected: _iconIndex),
    );
    if (picked != null && mounted) {
      setState(() {
        _chosenIcon = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final medicine = Medicine(
        id: _medicineId,
        name: _nameController.text.trim(),
        dose: _doseController.text.trim(),
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        createdOn: _isEditing ? widget.existing!.createdOn : todayKey(),
        iconIndex: _iconIndex,
      );
      Navigator.pop(context, MedicineFormResult.saved(medicine));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDeleteMedicineDialog(context);
    if (!confirmed || !mounted) return;
    Navigator.pop(context, const MedicineFormResult.removed());
  }

  // ---------- Screen parts ----------

  InputDecoration _decoration(String hint) {
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: scheme.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _label(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: _chooseIcon,
          borderRadius: BorderRadius.circular(70),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PillBadge(index: _iconIndex, size: 130, circle: true),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary,
                  child: Icon(Icons.edit, size: 16, color: scheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to change icon',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedTime.format(context),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          _isEditing ? 'Edit Medicine' : 'Add Medicine',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIconHeader(),
              const SizedBox(height: 24),
              _label('Medicine Name', isRequired: true),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('For example: Panadol 500mg'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter the medicine name'
                    : null,
              ),
              const SizedBox(height: 18),
              _label('Dose', isRequired: true),
              TextFormField(
                controller: _doseController,
                decoration: _decoration('For example: 1 tablet'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter the dose'
                    : null,
              ),
              const SizedBox(height: 18),
              _label('Time'),
              _buildTimeField(),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Save changes' : 'Add Medicine'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Medicine'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The bottom sheet that lets the user pick one of the nine pill pictures.
class _IconPicker extends StatelessWidget {
  final int selected;

  const _IconPicker({required this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose an icon',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < PillImage.count; i++)
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.pop(context, i),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: i == selected
                              ? scheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: PillBadge(index: i, size: 72),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
