class Session {
  final int id;
  final int activityId;
  final DateTime startAt;
  final DateTime? endAt;

  Session({
    required this.id,
    required this.activityId,
    required this.startAt,
    this.endAt,
  });

  bool get isRunning => endAt == null;

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int,
      activityId: map['activityId'] as int,
      startAt: DateTime.parse(map['startAt'] as String),
      endAt: map['endAt'] != null ? DateTime.parse(map['endAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityId': activityId,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
    };
  }
}
