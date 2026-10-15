import 'package:flutter/material.dart';
import '../models/medicine.dart';

/// Returns today's date as text, like 2026-10-15.
/// We use it to know which day a dose belongs to.
String todayKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}

/// Small helpers added on top of the Medicine class.
extension MedicineTime on Medicine {
  /// Minutes since midnight. 8:30 AM becomes 510. Easy to compare and sort.
  int get minutesOfDay => hour * 60 + minute;

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}
