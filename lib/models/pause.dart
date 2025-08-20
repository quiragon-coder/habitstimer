class Pause {
  final int id;
  final int sessionId;
  final DateTime startAt;
  final DateTime? endAt;

  const Pause({
    required this.id,
    required this.sessionId,
    required this.startAt,
    this.endAt,
  });

  bool get isRunning => endAt == null;

  factory Pause.fromMap(Map<String, dynamic> map) {
    return Pause(
      id: map['id'] as int,
      sessionId: map['sessionId'] as int,
      startAt: DateTime.parse(map['startAt'] as String),
      endAt: map['endAt'] != null ? DateTime.parse(map['endAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
    };
  }
}
