enum DoseStatus { taken, skipped }

/// One record: "this medicine, on this day, was taken (or skipped)".
class DoseLog {
  final int medicineId;
  final String date; // like 2026-10-15
  final DoseStatus status;

  const DoseLog({
    required this.medicineId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'date': date,
    'status': status.name,
  };

  factory DoseLog.fromJson(Map<String, dynamic> json) => DoseLog(
    medicineId: json['medicineId'] as int,
    date: json['date'] as String,
    status: DoseStatus.values.byName(json['status'] as String),
  );
}
