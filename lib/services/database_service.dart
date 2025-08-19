// lib/services/database_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:habits_timer/models/activity.dart';
import 'package:habits_timer/models/session.dart';
import 'package:habits_timer/models/pause.dart';

/// Implémentation *en mémoire* pour faire tourner l'app sans SQLite.
/// - Fournit toutes les méthodes attendues par l'UI actuelle.
/// - API stable pour remplacer plus tard par une vraie BDD (sqflite).
class DatabaseService {
  // --- Stockage en mémoire ----------------------------------------------------
  final List<Activity> _activities = <Activity>[];
  final List<Session> _sessions = <Session>[];

  int _nextActivityId = 1;
  int _nextSessionId = 1;
  int _nextPauseId = 1;

  // --- Activities -------------------------------------------------------------

  /// Pour compat avec certains appels existants (providers.dart)
  Future<List<Activity>> getActivities() async => getAllActivities();

  Future<List<Activity>> getAllActivities() async {
    // Tri par id croissant (optionnel)
    final copy = List<Activity>.from(_activities);
    copy.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    return copy;
  }

  /// Ajoute une activité.
  Future<Activity> addActivity(Activity a) async {
    final withId = a.copyWith(id: _nextActivityId++);
    _activities.add(withId);
    return withId;
  }

  /// Parfois l’UI appelle addActivity avec juste un nom => helper
  Future<Activity> addActivityWithName(String name) async {
    return addActivity(Activity(
      id: null,
      name: name,
      emoji: '⏱️',
      color: Colors.blue.value,
      goalMinutesPerDay: null,
      goalMinutesPerWeek: null,
      goalMinutesPerMonth: null,
      goalMinutesPerYear: null,
    ));
  }

  /// Supprime une activité. Retourne 1 si supprimée, 0 sinon.
  Future<int> deleteActivity(int id) async {
    final before = _activities.length;
    _activities.removeWhere((a) => a.id == id);
    // Supprime aussi ses sessions
    _sessions.removeWhere((s) => s.activityId == id);
    return before == _activities.length ? 0 : 1;
  }

  // --- Sessions ----------------------------------------------------------------

  /// Renvoie la session en cours pour une activité (ou null).
  Future<Session?> getRunningSession({int? activityId}) async {
    try {
      return _sessions.firstWhere(
            (s) => s.end == null && (activityId == null || s.activityId == activityId),
      );
    } catch (_) {
      return null;
    }
  }

  /// Démarre une nouvelle session (arrête l’ancienne si elle existe).
  Future<Session> startSession(int activityId) async {
    // Stoppe une éventuelle session en cours
    final running = await getRunningSession(activityId: activityId);
    if (running != null) {
      await stopSession(running.id, activityId);
    }

    final session = Session(
      id: _nextSessionId++,
      activityId: activityId,
      start: DateTime.now(),
      end: null,
      pauses: const <Pause>[],
    );
    _sessions.add(session);
    return session;
  }

  /// Pause/resume par (sessionId, activityId) – signature présente dans le code.
  Future<void> togglePause(int? sessionId, int activityId) async {
    // Trouve la session ciblée : l’id précis sinon la session en cours pour l’activité.
    final s = sessionId != null
        ? _sessions.firstWhere((x) => x.id == sessionId, orElse: () => throw StateError('Session introuvable'))
        : (await getRunningSession(activityId: activityId));

    if (s == null) return;

    // Si la session est déjà terminée, on ignore.
    if (s.end != null) return;

    // Si une pause est ouverte => on la clôt. Sinon on en ouvre une.
    final open = s.pauses.where((p) => p.endAt == null).toList();
    if (open.isNotEmpty) {
      final fixed = s.pauses
          .map((p) => p.endAt == null ? p.copyWith(endAt: DateTime.now()) : p)
          .toList(growable: false);
      _replaceSession(s.copyWith(pauses: fixed));
    } else {
      final newPause = Pause(id: _nextPauseId++, sessionId: s.id, startAt: DateTime.now(), endAt: null);
      _replaceSession(s.copyWith(pauses: [...s.pauses, newPause]));
    }
  }

  /// Pause/resume par activité (utilisé par ActivityControls).
  Future<void> togglePauseByActivity(int activityId) async {
    await togglePause(null, activityId);
  }

  /// Stop par (sessionId, activityId) – signature présente dans le code.
  Future<void> stopSession(int? sessionId, int activityId) async {
    final s = sessionId != null
        ? _sessions.firstWhere((x) => x.id == sessionId, orElse: () => throw StateError('Session introuvable'))
        : (await getRunningSession(activityId: activityId));

    if (s == null) return;
    if (s.end != null) return;

    // Si une pause est ouverte => on la ferme d’abord.
    final hasOpenPause = s.pauses.any((p) => p.endAt == null);
    List<Pause> pauses = s.pauses;
    if (hasOpenPause) {
      pauses = s.pauses
          .map((p) => p.endAt == null ? p.copyWith(endAt: DateTime.now()) : p)
          .toList(growable: false);
    }

    _replaceSession(s.copyWith(end: DateTime.now(), pauses: pauses));
  }

  /// Stop par activité (utilisé par ActivityControls).
  Future<void> stopSessionByActivity(int activityId) async {
    await stopSession(null, activityId);
  }

  // --- Statistiques & requêtes -------------------------------------------------

  /// Sessions entre [start] et [end], optionnellement filtrées par activité.
  Future<List<Session>> getSessionsBetween(
      DateTime start,
      DateTime end, {
        int? activityId,
      }) async {
    return _sessions
        .where((s) {
      final inActivity = activityId == null || s.activityId == activityId;
      final sStart = s.start;
      final sEnd = s.end ?? DateTime.now();
      return inActivity && sEnd.isAfter(start) && sStart.isBefore(end);
    })
        .map((s) => s.copyWith(pauses: [...s.pauses])) // copie “immuable”
        .toList(growable: false);
  }

  /// Minutes actives sur un jour (toutes activités si [activityId] null).
  Future<int> dailyActiveMinutes(DateTime day, {int? activityId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final list = await getSessionsBetween(start, end, activityId: activityId);
    int minutes = 0;
    for (final s in list) {
      minutes += _activeMinutesInRange(s, start, end);
    }
    return minutes;
  }

  /// Minutes actives par heure (24 valeurs) pour un jour.
  Future<List<int>> hourlyActiveMinutes(DateTime day, {required int activityId}) async {
    final startDay = DateTime(day.year, day.month, day.day);
    final List<int> buckets = List<int>.filled(24, 0);
    for (int h = 0; h < 24; h++) {
      final from = startDay.add(Duration(hours: h));
      final to = from.add(const Duration(hours: 1));
      final list = await getSessionsBetween(from, to, activityId: activityId);
      int m = 0;
      for (final s in list) {
        m += _activeMinutesInRange(s, from, to);
      }
      buckets[h] = m;
    }
    return buckets;
  }

  /// Minutes actives sur la semaine contenant [day].
  Future<int> minutesForWeek(DateTime day, int? activityId) async {
    // Lundi 00:00
    final weekday = day.weekday; // 1..7 (Mon..Sun)
    final monday = DateTime(day.year, day.month, day.day).subtract(Duration(days: weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));
    final list = await getSessionsBetween(start, end, activityId: activityId);
    int minutes = 0;
    for (final s in list) {
      minutes += _activeMinutesInRange(s, start, end);
    }
    return minutes;
  }

  // --- Export / Import / Maintenance ------------------------------------------

  /// Chemin base de données (placeholder pour compat UI).
  Future<String> databasePath() async {
    return 'memory://habits_timer'; // fictif
  }

  /// Exporte les données (activités + sessions + pauses) au format JSON.
  Future<String> exportJson() async {
    final data = {
      'activities': _activities.map((a) => a.toMap()).toList(),
      'sessions': _sessions.map((s) => _sessionToMap(s)).toList(),
    };
    return jsonEncode(data);
  }

  /// Importe des données JSON (remplace l’état courant).
  Future<void> importJson(String jsonStr) async {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    _activities.clear();
    _sessions.clear();
    _nextActivityId = 1;
    _nextSessionId = 1;
    _nextPauseId = 1;

    final acts = (map['activities'] as List?) ?? const [];
    for (final raw in acts) {
      final a = Activity.fromMap(Map<String, dynamic>.from(raw as Map));
      final fixed = a.copyWith(id: _nextActivityId++);
      _activities.add(fixed);
    }

    final sess = (map['sessions'] as List?) ?? const [];
    for (final raw in sess) {
      final s = _sessionFromMap(Map<String, dynamic>.from(raw as Map));
      final fixed = s.copyWith(id: _nextSessionId++);
      _sessions.add(fixed);
    }
  }

  /// Reset complet (efface tout).
  Future<void> resetDatabase() async {
    _activities.clear();
    _sessions.clear();
    _nextActivityId = 1;
    _nextSessionId = 1;
    _nextPauseId = 1;
  }

  // --- Helpers internes --------------------------------------------------------

  void _replaceSession(Session s) {
    final idx = _sessions.indexWhere((x) => x.id == s.id);
    if (idx >= 0) {
      _sessions[idx] = s;
    }
  }

  /// Minutes actives (temps total – pauses) d’une session tronquée à [from; to].
  int _activeMinutesInRange(Session s, DateTime from, DateTime to) {
    final sStart = s.start.isAfter(from) ? s.start : from;
    final sEnd = (s.end ?? DateTime.now()).isBefore(to) ? (s.end ?? DateTime.now()) : to;
    if (!sEnd.isAfter(sStart)) return 0;

    int total = sEnd.difference(sStart).inMinutes;

    // Soustrait les pauses qui intersectent la fenêtre
    for (final p in s.pauses) {
      final pStart = p.startAt.isAfter(from) ? p.startAt : from;
      final rawEnd = p.endAt ?? DateTime.now();
      final pEnd = rawEnd.isBefore(to) ? rawEnd : to;
      if (pEnd.isAfter(pStart)) {
        total -= pEnd.difference(pStart).inMinutes;
      }
    }

    return total.clamp(0, 1 << 30);
    // ^ évite le négatif si pauses > durée.
  }

  Map<String, dynamic> _sessionToMap(Session s) => {
    'id': s.id,
    'activityId': s.activityId,
    'start': s.start.toIso8601String(),
    'end': s.end?.toIso8601String(),
    'pauses': s.pauses.map((p) => p.toMap()).toList(),
  };

  Session _sessionFromMap(Map<String, dynamic> m) {
    final pauses = ((m['pauses'] as List?) ?? const [])
        .map((p) => Pause.fromMap(Map<String, dynamic>.from(p as Map)))
        .toList(growable: false);
    return Session(
      id: m['id'] as int? ?? 0,
      activityId: m['activityId'] as int,
      start: DateTime.parse(m['start'] as String),
      end: m['end'] == null ? null : DateTime.parse(m['end'] as String),
      pauses: pauses,
    );
  }
}
