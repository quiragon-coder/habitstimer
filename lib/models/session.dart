class Session {
  final int? id;
  final int activityId;
  final DateTime startAt;
  final DateTime? endAt;

  const Session({
    this.id,
    required this.activityId,
    required this.startAt,
    this.endAt,
  });

  bool get isRunning => endAt == null;

  factory Session.fromMap(Map<String, dynamic> m) => Session(
    id: m['id'] as int?,
    activityId: m['activity_id'] as int,
    startAt: DateTime.parse(m['start_at'] as String),
    endAt: m['end_at'] == null ? null : DateTime.parse(m['end_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'activity_id': activityId,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt?.toIso8601String(),
  };
}
