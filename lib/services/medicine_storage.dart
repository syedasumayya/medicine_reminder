import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

class MedicineStorage {
  static const String _key = 'medicines';

  Future<List<Medicine>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_key);
    if (text == null) return [];
    final list = jsonDecode(text) as List<dynamic>;
    return list
        .map((item) => Medicine.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Medicine> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final text = jsonEncode(medicines.map((m) => m.toJson()).toList());
    await prefs.setString(_key, text);
  }
}
