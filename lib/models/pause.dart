class Pause {
  final int? id;
  final int sessionId;
  final DateTime startAt;
  final DateTime? endAt;

  const Pause({
    this.id,
    required this.sessionId,
    required this.startAt,
    this.endAt,
  });

  bool get isPaused => endAt == null;

  factory Pause.fromMap(Map<String, dynamic> m) => Pause(
    id: m['id'] as int?,
    sessionId: m['session_id'] as int,
    startAt: DateTime.parse(m['start_at'] as String),
    endAt: m['end_at'] == null ? null : DateTime.parse(m['end_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id': sessionId,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt?.toIso8601String(),
  };
}
