class Medicine {
  final int id;
  final String name;
  final String dose;
  final int hour; // 0 to 23
  final int minute; // 0 to 59

  const Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.hour,
    required this.minute,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dose': dose,
    'hour': hour,
    'minute': minute,
  };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    id: json['id'] as int,
    name: json['name'] as String,
    dose: json['dose'] as String,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
  );
}
