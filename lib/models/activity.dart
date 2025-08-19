import 'dart:convert';

class Activity {
  final int? id;
  final String name;
  final int? goalMinutesPerWeek;
  final int? goalDaysPerWeek;
  final int? goalMinutesPerDay;

  const Activity({
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

  factory Activity.fromMap(Map<String, dynamic> m) => Activity(
    id: m['id'] as int?,
    name: m['name'] as String,
    goalMinutesPerWeek: m['goal_minutes_per_week'] as int?,
    goalDaysPerWeek: m['goal_days_per_week'] as int?,
    goalMinutesPerDay: m['goal_minutes_per_day'] as int?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'goal_minutes_per_week': goalMinutesPerWeek,
    'goal_days_per_week': goalDaysPerWeek,
    'goal_minutes_per_day': goalMinutesPerDay,
  };

  static List<Activity> listFromJson(String jsonStr) {
    final l = json.decode(jsonStr) as List<dynamic>;
    return l.map((e) => Activity.fromMap(e as Map<String, dynamic>)).toList();
  }
}
