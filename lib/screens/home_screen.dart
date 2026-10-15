import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/medicine_storage.dart';
import 'add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MedicineStorage _storage = MedicineStorage();
  List<Medicine> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final saved = await _storage.load();
    if (!mounted) return;
    setState(() {
      _medicines = saved;
      _loading = false;
    });
  }

  Future<void> _openAddScreen() async {
    final newMedicine = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
    );
    if (newMedicine != null && mounted) {
      setState(() {
        _medicines.add(newMedicine);
      });
      await _storage.save(_medicines);
    }
  }

  Future<void> _deleteMedicine(int index) async {
    setState(() {
      _medicines.removeAt(index);
    });
    await _storage.save(_medicines);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_medicines.isEmpty) {
      return const Center(
        child: Text(
          'No medicines yet.\nTap + to add one.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: _medicines.length,
      itemBuilder: (context, index) {
        final medicine = _medicines[index];
        final time = TimeOfDay(hour: medicine.hour, minute: medicine.minute);
        return ListTile(
          leading: const Icon(Icons.medication),
          title: Text(medicine.name),
          subtitle: Text('${medicine.dose}  •  ${time.format(context)}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _deleteMedicine(index),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        tooltip: 'Add medicine',
        child: const Icon(Icons.add),
      ),
    );
  }
}
