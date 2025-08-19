class Activity {
  final int? id;
  final String name;
  // goals (minutes)
  final int? goalMinutesPerWeek;
  final int? goalDaysPerWeek;
  final int? goalMinutesPerDay;

  Activity({
    this.id,
    required this.name,
    this.goalMinutesPerWeek,
    this.goalDaysPerWeek,
    this.goalMinutesPerDay,
  });

  Activity copyWith({
    int? id,
    String? name,
    int? goalMinutesPerWeek,
    int? goalDaysPerWeek,
    int? goalMinutesPerDay,
  }) => Activity(
    id: id ?? this.id,
    name: name ?? this.name,
    goalMinutesPerWeek: goalMinutesPerWeek ?? this.goalMinutesPerWeek,
    goalDaysPerWeek: goalDaysPerWeek ?? this.goalDaysPerWeek,
    goalMinutesPerDay: goalMinutesPerDay ?? this.goalMinutesPerDay,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'goalMinutesPerWeek': goalMinutesPerWeek,
    'goalDaysPerWeek': goalDaysPerWeek,
    'goalMinutesPerDay': goalMinutesPerDay,
  };

  static Activity fromMap(Map<String, dynamic> m) => Activity(
    id: m['id'] as int?,
    name: m['name'] as String,
    goalMinutesPerWeek: m['goalMinutesPerWeek'] as int?,
    goalDaysPerWeek: m['goalDaysPerWeek'] as int?,
    goalMinutesPerDay: m['goalMinutesPerDay'] as int?,
  );
}
