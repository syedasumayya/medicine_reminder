class Medicine {
  final int id;
  final String name;
  final String dose;
  final int hour; // 0 to 23
  final int minute; // 0 to 59

  /// The day this medicine was added, like 2026-10-15.
  /// It is null for medicines saved before this feature existed.
  final String? createdOn;

  const Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.hour,
    required this.minute,
    this.createdOn,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dose': dose,
    'hour': hour,
    'minute': minute,
    if (createdOn != null) 'createdOn': createdOn,
  };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    id: json['id'] as int,
    name: json['name'] as String,
    dose: json['dose'] as String,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    createdOn: json['createdOn'] as String?,
  );
}
