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

  bool get isRunning => endAt == null;

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as int?,
        activityId: map['activityId'] as int,
        startAt: DateTime.parse(map['startAt'] as String),
        endAt: map['endAt'] != null ? DateTime.parse(map['endAt'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'activityId': activityId,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
      };
}

class Pause {
  final int? id;
  final int sessionId;
  final DateTime startAt;
  final DateTime? endAt;

  Pause({
    this.id,
    required this.sessionId,
    required this.startAt,
    this.endAt,
  });

  bool get isPaused => endAt == null;

  factory Pause.fromMap(Map<String, dynamic> map) => Pause(
        id: map['id'] as int?,
        sessionId: map['sessionId'] as int,
        startAt: DateTime.parse(map['startAt'] as String),
        endAt: map['endAt'] != null ? DateTime.parse(map['endAt'] as String) : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
      };
}
