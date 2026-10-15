import 'package:flutter/material.dart';
import '../models/medicine.dart';

class AddMedicineScreen extends StatefulWidget {
  /// If this is given, the screen edits that medicine instead of adding a new one.
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

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _doseController = TextEditingController(text: existing?.dose ?? '');
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

  void _save() {
    if (_formKey.currentState!.validate()) {
      final medicine = Medicine(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.remainder(100000000),
        name: _nameController.text.trim(),
        dose: _doseController.text.trim(),
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );
      Navigator.pop(context, medicine);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medicine' : 'Add Medicine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter the medicine name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doseController,
                decoration: const InputDecoration(
                  labelText: 'Dose (for example: 1 tablet)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter the dose'
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(_selectedTime.format(context)),
                onTap: _pickTime,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Save changes' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
