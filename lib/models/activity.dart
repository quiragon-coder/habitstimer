class Activity {
  final int? id;
  final String name;
  final int? goalMinutesPerWeek;
  final int? goalDaysPerWeek;
  final int? goalMinutesPerDay;
  final DateTime? createdAt;

  Activity({
    this.id,
    required this.name,
    this.goalMinutesPerWeek,
    this.goalDaysPerWeek,
    this.goalMinutesPerDay,
    this.createdAt,
  });

  Activity copyWith({
    int? id,
    String? name,
    int? goalMinutesPerWeek,
    int? goalDaysPerWeek,
    int? goalMinutesPerDay,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      goalMinutesPerWeek: goalMinutesPerWeek ?? this.goalMinutesPerWeek,
      goalDaysPerWeek: goalDaysPerWeek ?? this.goalDaysPerWeek,
      goalMinutesPerDay: goalMinutesPerDay ?? this.goalMinutesPerDay,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Activity.fromMap(Map<String, dynamic> map) => Activity(
        id: map['id'] as int?,
        name: map['name'] as String,
        goalMinutesPerWeek: map['goalMinutesPerWeek'] as int?,
        goalDaysPerWeek: map['goalDaysPerWeek'] as int?,
        goalMinutesPerDay: map['goalMinutesPerDay'] as int?,
        createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'goalMinutesPerWeek': goalMinutesPerWeek,
        'goalDaysPerWeek': goalDaysPerWeek,
        'goalMinutesPerDay': goalMinutesPerDay,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
