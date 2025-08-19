// lib/services/database_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/session.dart';

/// Service simulant une base de données en mémoire.
/// 👉 Plus tard, tu pourras brancher une vraie base SQLite/Hive.
class DatabaseService {
  final List<Activity> _activities = [];
  final List<Session> _sessions = [];

  /// Retourne toutes les activités
  Future<List<Activity>> getActivities() async {
    return _activities;
  }

  /// Ajoute une activité
  Future<void> addActivity(Activity activity) async {
    _activities.add(activity);
  }

  /// Supprime une activité par son ID
  Future<int> deleteActivity(int id) async {
    final before = _activities.length;
    _activities.removeWhere((a) => a.id == id);
    return before - _activities.length;
  }

  /// Démarre une session pour une activité
  Future<Session> startSession(int activityId) async {
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch,
      activityId: activityId,
      start: DateTime.now(),
      pauses: [],
    );
    _sessions.add(session);
    return session;
  }

  /// Stoppe une session
  Future<void> stopSession(int sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final old = _sessions[index];
    _sessions[index] = old.copyWith(end: DateTime.now());
  }

  /// Ajoute/enlève une pause dans une session
  Future<void> togglePause(int sessionId, bool isPaused) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final old = _sessions[index];

    if (isPaused) {
      // Reprendre → on ferme la dernière pause
      final pauses = [...old.pauses];
      if (pauses.isNotEmpty && pauses.last.endAt == null) {
        pauses[pauses.length - 1] =
            Pause(startAt: pauses.last.startAt, endAt: DateTime.now());
      }
      _sessions[index] = old.copyWith(pauses: pauses);
    } else {
      // Mettre en pause → on ajoute une nouvelle pause
      final pauses = [...old.pauses, Pause(startAt: DateTime.now())];
      _sessions[index] = old.copyWith(pauses: pauses);
    }
  }

  /// Récupère toutes les sessions d’une activité
  Future<List<Session>> getSessionsForActivity(int activityId) async {
    return _sessions.where((s) => s.activityId == activityId).toList();
  }

  /// Export JSON (activités + sessions)
  Future<String> exportJson() async {
    final data = {
      "activities": _activities.map((a) => a.toMap()).toList(),
      "sessions": _sessions.map((s) => s.toMap()).toList(),
    };
    return jsonEncode(data);
  }

  /// Import JSON
  Future<void> importJson(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    _activities.clear();
    _sessions.clear();

    if (data["activities"] != null) {
      _activities.addAll(
          (data["activities"] as List).map((a) => Activity.fromMap(a)));
    }
    if (data["sessions"] != null) {
      _sessions.addAll(
          (data["sessions"] as List).map((s) => Session.fromMap(s)));
    }
  }

  /// Réinitialise la "base"
  Future<void> resetDatabase() async {
    _activities.clear();
    _sessions.clear();
  }
}
