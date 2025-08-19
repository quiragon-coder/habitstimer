class Activity {
  final int? id;
  final String name;
  final String emoji;
  final int color;
  final int? goalMinutesPerDay;
  final int? goalMinutesPerWeek;
  final int? goalMinutesPerMonth;
  final int? goalMinutesPerYear;

  Activity({
    this.id,
    required this.name,
    this.emoji = "⏱️",
    this.color = 0xFF2196F3,
    this.goalMinutesPerDay,
    this.goalMinutesPerWeek,
    this.goalMinutesPerMonth,
    this.goalMinutesPerYear,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'color': color,
      'goal_minutes_per_day': goalMinutesPerDay,
      'goal_minutes_per_week': goalMinutesPerWeek,
      'goal_minutes_per_month': goalMinutesPerMonth,
      'goal_minutes_per_year': goalMinutesPerYear,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'] ?? "⏱️",
      color: map['color'] ?? 0xFF2196F3,
      goalMinutesPerDay: map['goal_minutes_per_day'],
      goalMinutesPerWeek: map['goal_minutes_per_week'],
      goalMinutesPerMonth: map['goal_minutes_per_month'],
      goalMinutesPerYear: map['goal_minutes_per_year'],
    );
  }
}
