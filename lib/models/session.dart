// lib/models/session.dart
import 'package:flutter/foundation.dart';

/// Représente une pause dans une session.
class Pause {
  final DateTime startAt;
  final DateTime? endAt;

  Pause({
    required this.startAt,
    this.endAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
    };
  }

  factory Pause.fromMap(Map<String, dynamic> map) {
    return Pause(
      startAt: DateTime.parse(map['startAt']),
      endAt: map['endAt'] != null ? DateTime.parse(map['endAt']) : null,
    );
  }
}

/// Représente une session d’activité.
class Session {
  final int id;
  final int activityId;
  final DateTime start;
  final DateTime? end;
  final List<Pause> pauses;

  const Session({
    required this.id,
    required this.activityId,
    required this.start,
    this.end,
    this.pauses = const [],
  });

  Session copyWith({
    int? id,
    int? activityId,
    DateTime? start,
    DateTime? end,
    List<Pause>? pauses,
  }) {
    return Session(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      start: start ?? this.start,
      end: end ?? this.end,
      pauses: pauses ?? this.pauses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityId': activityId,
      'start': start.toIso8601String(),
      'end': end?.toIso8601String(),
      'pauses': pauses.map((p) => p.toMap()).toList(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      activityId: map['activityId'],
      start: DateTime.parse(map['start']),
      end: map['end'] != null ? DateTime.parse(map['end']) : null,
      pauses: map['pauses'] != null
          ? List<Map<String, dynamic>>.from(map['pauses'])
          .map((p) => Pause.fromMap(p))
          .toList()
          : [],
    );
  }
}
