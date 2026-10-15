import 'package:flutter/material.dart';
import '../models/medicine.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Medicine> _sampleMedicines = [
    Medicine(name: 'Panadol', dose: '1 tablet', time: '8:00 AM'),
    Medicine(name: 'Vitamin D', dose: '1 capsule', time: '1:00 PM'),
    Medicine(name: 'Amoxicillin', dose: '2 tablets', time: '9:00 PM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: ListView.builder(
        itemCount: _sampleMedicines.length,
        itemBuilder: (context, index) {
          final medicine = _sampleMedicines[index];
          return ListTile(
            leading: const Icon(Icons.medication),
            title: Text(medicine.name),
            subtitle: Text(medicine.dose),
            trailing: Text(medicine.time),
          );
        },
      ),
    );
  }
}
