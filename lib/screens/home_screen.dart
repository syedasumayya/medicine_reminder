import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Medicine> _medicines = [
    const Medicine(name: 'Panadol', dose: '1 tablet', time: '8:00 AM'),
    const Medicine(name: 'Vitamin D', dose: '1 capsule', time: '1:00 PM'),
    const Medicine(name: 'Amoxicillin', dose: '2 tablets', time: '9:00 PM'),
  ];

  Future<void> _openAddScreen() async {
    final newMedicine = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
    );
    if (newMedicine != null && mounted) {
      setState(() {
        _medicines.add(newMedicine);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: ListView.builder(
        itemCount: _medicines.length,
        itemBuilder: (context, index) {
          final medicine = _medicines[index];
          return ListTile(
            leading: const Icon(Icons.medication),
            title: Text(medicine.name),
            subtitle: Text(medicine.dose),
            trailing: Text(medicine.time),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        tooltip: 'Add medicine',
        child: const Icon(Icons.add),
      ),
    );
  }
}
