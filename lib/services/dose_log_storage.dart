import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dose_log.dart';

class DoseLogStorage {
  static const String _key = 'dose_logs';

  Future<List<DoseLog>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_key);
    if (text == null) return [];
    final list = jsonDecode(text) as List<dynamic>;
    return list
        .map((item) => DoseLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<DoseLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final text = jsonEncode(logs.map((l) => l.toJson()).toList());
    await prefs.setString(_key, text);
  }
}
