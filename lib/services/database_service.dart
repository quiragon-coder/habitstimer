import 'dart:async';

import 'package:habits_timer/models/activity.dart';
import 'package:habits_timer/models/session.dart';
import 'package:habits_timer/models/pause.dart';

/// Service de données en mémoire.
/// Impl simple pour débloquer l’app (création + listing + sessions).
/// Tu pourras plus tard brancher SQLite en gardant les mêmes signatures.
class DatabaseService {
  // --- Singleton simple (facultatif mais pratique) ---
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // --- Stores en mémoire ---
  final List<Activity> _activities = <Activity>[];
  final List<Session> _sessions = <Session>[];
  final List<Pause> _pauses = <Pause>[];

  int _nextActivityId = 1;
  int _nextSessionId = 1;
  int _nextPauseId = 1;

  // ----------------------------------------------------
  // ACTIVITIES
  // ----------------------------------------------------

  /// Ajoute une activité. Assigne un id auto-incrémenté.
  Future<void> addActivity(Activity a) async {
    final toAdd = Activity(
      id: _nextActivityId++,
      name: a.name,
      emoji: a.emoji,
      color: a.color,
      goalMinutesPerDay: a.goalMinutesPerDay,
      goalMinutesPerWeek: a.goalMinutesPerWeek,
      goalMinutesPerMonth: a.goalMinutesPerMonth,
      goalMinutesPerYear: a.goalMinutesPerYear,
    );
    _activities.add(toAdd);
  }

  /// Retourne toutes les activités.
  Future<List<Activity>> getAllActivities() async {
    // On renvoie une copie immuable pour éviter les modifs externes.
    return List<Activity>.unmodifiable(_activities);
  }

  // ----------------------------------------------------
  // SESSIONS (play/pause/stop)
  // ----------------------------------------------------

  /// Démarre une session pour une activité (et stoppe l’ancienne si besoin).
  Future<Session> startSession(int activityId) async {
    // S’il existe déjà une session en cours pour cette activité, on la stoppe.
    final existing = _sessions.firstWhere(
          (s) => s.activityId == activityId && s.endAt == null,
      orElse: () => Session(id: -1, activityId: -1, startAt: DateTime(1900)),
    );
    if (existing.id != -1) {
      await stopSessionByActivity(activityId);
    }

    final now = DateTime.now();
    final s = Session(
      id: _nextSessionId++,
      activityId: activityId,
      startAt: now,
      endAt: null,
    );
    _sessions.add(s);
    return s;
  }

  /// Renvoie la session en cours pour une activité (ou null).
  Future<Session?> getRunningSession(int activityId) async {
    try {
      return _sessions.firstWhere(
            (s) => s.activityId == activityId && s.endAt == null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Bascule pause/reprise pour une session (par id).
  Future<void> togglePause(int sessionId) async {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    if (session.endAt != null) return; // déjà terminée

    // y a-t-il une pause ouverte ?
    try {
      final open = _pauses.firstWhere(
            (p) => p.sessionId == sessionId && p.endAt == null,
      );
      // on ferme la pause
      final idx = _pauses.indexOf(open);
      _pauses[idx] = Pause(
        id: open.id,
        sessionId: open.sessionId,
        startAt: open.startAt,
        endAt: DateTime.now(),
      );
    } catch (_) {
      // pas de pause ouverte -> on en ouvre une
      _pauses.add(
        Pause(
          id: _nextPauseId++,
          sessionId: sessionId,
          startAt: DateTime.now(),
          endAt: null,
        ),
      );
    }
  }

  /// Bascule pause/reprise par activité (pratique côté UI).
  Future<void> togglePauseByActivity(int activityId) async {
    final s = await getRunningSession(activityId);
    if (s == null) return;
    await togglePause(s.id);
  }

  /// Stoppe une session (par id) en fermant toute pause ouverte.
  Future<void> stopSession(int sessionId) async {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return;

    final current = _sessions[idx];
    if (current.endAt != null) return;

    // Fermer pause ouverte s’il y en a une
    final openPauseIdx = _pauses.indexWhere(
          (p) => p.sessionId == sessionId && p.endAt == null,
    );
    if (openPauseIdx != -1) {
      final open = _pauses[openPauseIdx];
      _pauses[openPauseIdx] = Pause(
        id: open.id,
        sessionId: open.sessionId,
        startAt: open.startAt,
        endAt: DateTime.now(),
      );
    }

    _sessions[idx] = Session(
      id: current.id,
      activityId: current.activityId,
      startAt: current.startAt,
      endAt: DateTime.now(),
    );
  }

  /// Stoppe la session en cours pour l’activité.
  Future<void> stopSessionByActivity(int activityId) async {
    final s = await getRunningSession(activityId);
    if (s == null) return;
    await stopSession(s.id);
  }

  // ----------------------------------------------------
  // QUERIES / STATS (helpers)
  // ----------------------------------------------------

  /// Sessions entre deux dates (inclusif/exclusif), filtre optionnel activité.
  Future<List<Session>> getSessionsBetween(
      DateTime start,
      DateTime end, {
        int? activityId,
      }) async {
    final safeEnd = end.isAfter(start) ? end : start;
    final list = _sessions.where((s) {
      if (activityId != null && s.activityId != activityId) return false;
      final sEnd = s.endAt ?? DateTime.now();
      // Intersections: [startAt, endAt] intersecte [start, safeEnd]
      final overlap =
      !(sEnd.isBefore(start) || s.startAt.isAfter(safeEnd));
      return overlap;
    }).toList();

    // On renvoie une copie
    return List<Session>.unmodifiable(list);
  }

  /// Minutes actives (sans pauses) pour une session.
  int _activeMinutesForSession(Session s) {
    final end = s.endAt ?? DateTime.now();
    var total = end.difference(s.startAt).inMinutes;

    // soustraire les pauses
    final pauses = _pauses.where((p) => p.sessionId == s.id).toList();
    for (final p in pauses) {
      final pend = p.endAt ?? DateTime.now();
      final mins = pend.difference(p.startAt).inMinutes;
      total -= mins;
    }
    if (total < 0) total = 0;
    return total;
  }

  /// Minutes actives pour une journée (toutes activités ou une seule).
  Future<int> minutesForDay(DateTime day, {int? activityId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final sessions = await getSessionsBetween(start, end, activityId: activityId);
    var sum = 0;
    for (final s in sessions) {
      // On rogne la session à la fenêtre [start, end)
      final sStart = s.startAt.isBefore(start) ? start : s.startAt;
      final sEnd = (s.endAt ?? DateTime.now()).isAfter(end) ? end : (s.endAt ?? DateTime.now());

      var minutes = sEnd.difference(sStart).inMinutes;

      // retirer pauses qui intersectent [start, end)
      final pauses = _pauses.where((p) => p.sessionId == s.id);
      for (final p in pauses) {
        final pStart = p.startAt.isBefore(start) ? start : p.startAt;
        final pEnd = (p.endAt ?? DateTime.now()).isAfter(end) ? end : (p.endAt ?? DateTime.now());
        if (!pEnd.isBefore(sStart) && !pStart.isAfter(sEnd)) {
          final overlapStart = pStart.isAfter(sStart) ? pStart : sStart;
          final overlapEnd = pEnd.isBefore(sEnd) ? pEnd : sEnd;
          final overlap = overlapEnd.difference(overlapStart).inMinutes;
          minutes -= overlap;
        }
      }

      if (minutes < 0) minutes = 0;
      sum += minutes;
    }
    return sum;
  }

  /// Minutes actives cumulées sur la semaine du [date] (ISO : lundi->dimanche).
  Future<int> minutesForWeek(DateTime date, int activityId) async {
    final monday = date.subtract(Duration(days: (date.weekday - 1)));
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += await minutesForDay(monday.add(Duration(days: i)), activityId: activityId);
    }
    return total;
  }

  /// Minutes actives par heure (24 cases) pour affichage en barres ce jour-là.
  Future<List<int>> hourlyActiveMinutes(DateTime day, {int? activityId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final buckets = List<int>.filled(24, 0);

    final sessions = await getSessionsBetween(start, end, activityId: activityId);

    // On découpe les sessions sur les heures (approx : par minute)
    for (final s in sessions) {
      final sStart = s.startAt.isBefore(start) ? start : s.startAt;
      final sEnd = (s.endAt ?? DateTime.now()).isAfter(end) ? end : (s.endAt ?? DateTime.now());

      // Liste des minutes "actives" (sans pause)
      final activeMinutes = <DateTime>[];
      var cursor = sStart;
      while (cursor.isBefore(sEnd)) {
        // si cette minute est dans une pause -> on saute
        final paused = _pauses.any((p) {
          if (p.sessionId != s.id) return false;
          final pStart = p.startAt;
          final pEnd = p.endAt ?? DateTime.now();
          return !(pEnd.isBefore(cursor) || pStart.isAfter(cursor.add(const Duration(minutes: 1))));
        });
        if (!paused) activeMinutes.add(cursor);
        cursor = cursor.add(const Duration(minutes: 1));
      }

      for (final m in activeMinutes) {
        final h = m.hour;
        buckets[h] = buckets[h] + 1;
      }
    }

    return buckets;
  }

  // ----------------------------------------------------
  // UTILS / DEBUG
  // ----------------------------------------------------

  /// Reset complet (utile pendant le dev).
  Future<void> resetAll() async {
    _activities.clear();
    _sessions.clear();
    _pauses.clear();
    _nextActivityId = 1;
    _nextSessionId = 1;
    _nextPauseId = 1;
  }
}
