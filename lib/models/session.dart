class Session {
  final int? id;
  final int activityId;
  final DateTime startAt;
  final DateTime? endAt;

  Session({
    this.id,
    required this.activityId,
    required this.startAt,
    this.endAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'activityId': activityId,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt?.toIso8601String(),
  };

  static Session fromMap(Map<String, dynamic> m) => Session(
    id: m['id'] as int?,
    activityId: m['activityId'] as int,
    startAt: DateTime.parse(m['startAt'] as String),
    endAt: (m['endAt'] == null) ? null : DateTime.parse(m['endAt'] as String),
  );
}
