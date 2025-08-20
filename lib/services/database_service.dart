import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:habits_timer/models/activity.dart';
import 'package:habits_timer/models/session.dart';
import 'package:habits_timer/models/pause.dart';

/// Implémentation simple "en mémoire"
/// - IDs auto-incrémentés
/// - Méthodes asynchrones pour imiter une vraie BDD
/// - Suffisant pour lancer l'app, créer/contrôler des timers, voir l'historique,
///   et alimenter des écrans basiques (jour/semaine/heure).
class DatabaseService {
  // --- Stockage en mémoire ---
  final List<Activity> _activities = [];
  final List<Session> _sessions = [];
  final List<Pause> _pauses = [];

  int _nextActivityId = 1;
  int _nextSessionId = 1;
  int _nextPauseId = 1;

  // ---------------------------------------------------------------------------
  // ACTIVITIES
  // ---------------------------------------------------------------------------

  Future<List<Activity>> getActivities() async {
    // renvoyer une copie (immutabilité simple)
    return List<Activity>.unmodifiable(_activities);
  }

  Future<int> addActivity(Activity a) async {
    final created = Activity(
      id: _nextActivityId++,
      name: a.name,
      emoji: a.emoji,
      color: a.color,
      goalMinutesPerDay: a.goalMinutesPerDay,
      goalMinutesPerWeek: a.goalMinutesPerWeek,
      goalMinutesPerMonth: a.goalMinutesPerMonth,
      goalMinutesPerYear: a.goalMinutesPerYear,
    );
    _activities.add(created);
    return created.id!;
  }

  /// Petit helper si tu appelles `createActivity("…")` depuis l’UI
  Future<int> createActivity(String name,
      {String emoji = "⏱️",
        int color = 0xFF2196F3,
        int? goalMinutesPerDay,
        int? goalMinutesPerWeek,
        int? goalMinutesPerMonth,
        int? goalMinutesPerYear}) async {
    return addActivity(Activity(
      name: name,
      emoji: emoji,
      color: color,
      goalMinutesPerDay: goalMinutesPerDay,
      goalMinutesPerWeek: goalMinutesPerWeek,
      goalMinutesPerMonth: goalMinutesPerMonth,
      goalMinutesPerYear: goalMinutesPerYear,
    ));
  }

  Future<int> deleteActivity(int id) async {
    final before = _activities.length;
    _activities.removeWhere((a) => a.id == id);

    // Supprimer aussi les sessions liées et leurs pauses
    final sessionIds = _sessions.where((s) => s.activityId == id).map((s) => s.id).toSet();
    _sessions.removeWhere((s) => s.activityId == id);
    _pauses.removeWhere((p) => sessionIds.contains(p.sessionId));

    return before - _activities.length; // nombre supprimé
  }

  // ---------------------------------------------------------------------------
  // SESSIONS
  // ---------------------------------------------------------------------------

  /// Démarre une session pour l’activité (et stoppe la session courante si besoin).
  Future<void> startSession(int activityId) async {
    // Stopper une session en cours pour cette activité (si elle existe).
    final running = await getRunningSession(activityId);
    if (running != null) {
      await stopSessionByActivity(activityId);
    }

    final s = Session(
      id: _nextSessionId++,
      activityId: activityId,
      startAt: DateTime.now(),
      endAt: null,
    );
    _sessions.add(s);
  }

  /// Retourne la session en cours (endAt == null) pour l’activité.
  Future<Session?> getRunningSession(int activityId) async {
    try {
      return _sessions.lastWhere(
            (s) => s.activityId == activityId && s.endAt == null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Met en pause / reprend la session (par activité).
  Future<void> togglePauseByActivity(int activityId) async {
    final running = await getRunningSession(activityId);
    if (running == null) return;

    final openPause = _pauses.lastWhere(
          (p) => p.sessionId == running.id && p.endAt == null,
      orElse: () => null as Pause, // on va tester null ensuite
    );

    if (openPause == null) {
      // Créer une pause (start)
      final p = Pause(
        id: _nextPauseId++,
        sessionId: running.id,
        startAt: DateTime.now(),
      );
      _pauses.add(p);
    } else {
      // Terminer la pause
      final idx = _pauses.indexWhere((x) => x.id == openPause.id);
      if (idx >= 0) {
        _pauses[idx] = Pause(
          id: openPause.id,
          sessionId: openPause.sessionId,
          startAt: openPause.startAt,
          endAt: DateTime.now(),
        );
      }
    }
  }

  /// Stoppe la session en cours pour l’activité (et clôture la pause si ouverte).
  Future<void> stopSessionByActivity(int activityId) async {
    final running = await getRunningSession(activityId);
    if (running == null) return;

    // Fermer une pause ouverte
    final openPause = _pauses.lastWhere(
          (p) => p.sessionId == running.id && p.endAt == null,
      orElse: () => null as Pause,
    );
    if (openPause != null) {
      final i = _pauses.indexWhere((x) => x.id == openPause.id);
      _pauses[i] = Pause(
        id: openPause.id,
        sessionId: openPause.sessionId,
        startAt: openPause.startAt,
        endAt: DateTime.now(),
      );
    }

    // Clore la session
    final si = _sessions.indexWhere((s) => s.id == running.id);
    if (si >= 0) {
      _sessions[si] = Session(
        id: running.id,
        activityId: running.activityId,
        startAt: running.startAt,
        endAt: DateTime.now(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // QUERIES / CALCULS
  // ---------------------------------------------------------------------------

  /// Sessions entre deux dates (option: filtrer par activité).
  Future<List<Session>> getSessionsBetween(DateTime from, DateTime to, {int? activityId}) async {
    final res = _sessions.where((s) {
      final st = s.startAt;
      // On compte la session si elle touche la plage [from, to)
      final ends = s.endAt ?? DateTime.now();
      final intersects = !(ends.isBefore(from) || st.isAfter(to));
      if (!intersects) return false;
      if (activityId != null && s.activityId != activityId) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return res;
  }

  /// Minutes actives sur une journée (0..23) pour alimenter un histogramme horaire.
  Future<List<int>> hourlyActiveMinutes(DateTime day, {required int activityId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final sessions = await getSessionsBetween(start, end, activityId: activityId);

    final buckets = List<int>.filled(24, 0);
    for (final s in sessions) {
      final realStart = s.startAt.isBefore(start) ? start : s.startAt;
      final realEnd = (s.endAt ?? DateTime.now()).isAfter(end) ? end : (s.endAt ?? DateTime.now());

      // Soustraire les pauses
      final pauses = _pauses.where((p) => p.sessionId == s.id).toList();
      final totalRanges = _subtractPauses(realStart, realEnd, pauses);

      for (final range in totalRanges) {
        final rs = range.$1;
        final re = range.$2;
        // Dispatch dans les heures
        var cursor = DateTime(rs.year, rs.month, rs.day, rs.hour);
        while (cursor.isBefore(re)) {
          final hourEnd = cursor.add(Duration(hours: 1));
          final segStart = rs.isAfter(cursor) ? rs : cursor;
          final segEnd = re.isBefore(hourEnd) ? re : hourEnd;

          final mins = segEnd.difference(segStart).inMinutes;
          if (mins > 0) {
            buckets[cursor.hour] += mins;
          }
          cursor = hourEnd;
        }
      }
    }
    return buckets;
  }

  /// Minutes totales sur la semaine (lundi → dimanche) pour une activité.
  Future<int> minutesForWeek(DateTime anyDate, int activityId) async {
    final monday = anyDate.subtract(Duration(days: (anyDate.weekday + 6) % 7));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));

    final sessions = await getSessionsBetween(start, end, activityId: activityId);
    var total = 0;

    for (final s in sessions) {
      final realStart = s.startAt.isBefore(start) ? start : s.startAt;
      final realEnd = (s.endAt ?? DateTime.now()).isAfter(end) ? end : (s.endAt ?? DateTime.now());
      final pauses = _pauses.where((p) => p.sessionId == s.id).toList();
      final ranges = _subtractPauses(realStart, realEnd, pauses);
      for (final r in ranges) {
        total += r.$2.difference(r.$1).inMinutes;
      }
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // EXPORT / RESET (simples, pour Settings)
  // ---------------------------------------------------------------------------

  /// Chemin "virtuel" juste pour l’UI (pas de vraie BDD ici)
  Future<String> databasePath() async => 'memory://habits_timer';

  Future<String> exportJson() async {
    final data = {
      'activities': _activities.map((a) => a.toMap()).toList(),
      'sessions': _sessions
          .map((s) => {
        'id': s.id,
        'activityId': s.activityId,
        'startAt': s.startAt.toIso8601String(),
        'endAt': s.endAt?.toIso8601String(),
      })
          .toList(),
      'pauses': _pauses
          .map((p) => {
        'id': p.id,
        'sessionId': p.sessionId,
        'startAt': p.startAt.toIso8601String(),
        'endAt': p.endAt?.toIso8601String(),
      })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importJson(String json) async {
    // Optionnel : tu pourras l’implémenter plus tard si besoin
    // (vider puis recharger _activities/_sessions/_pauses)
    // Pour l’instant on ne fait rien pour éviter de casser.
    return;
  }

  Future<void> resetDatabase() async {
    _activities.clear();
    _sessions.clear();
    _pauses.clear();
    _nextActivityId = 1;
    _nextSessionId = 1;
    _nextPauseId = 1;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Soustrait les pauses au range [start, end] et renvoie une liste
  /// de périodes actives (Tuple simple).
  List<(_D, _D)> _subtractPauses(DateTime start, DateTime end, List<Pause> pauses) {
    // On part de 1 seul range actif
    var ranges = <(_D, _D)>[(start, end)];

    for (final p in pauses) {
      final pStart = p.startAt;
      final pEnd = p.endAt ?? DateTime.now();
      final newRanges = <(_D, _D)>[];

      for (final r in ranges) {
        final rs = r.$1;
        final re = r.$2;

        // Pas de recouvrement
        if (pEnd.isBefore(rs) || pStart.isAfter(re)) {
          newRanges.add((rs, re));
          continue;
        }
        // Pause couvre tout le range
        if (!pStart.isAfter(rs) && !pEnd.isBefore(re)) {
          // on enlève le range
          continue;
        }
        // Découpe à gauche
        if (pStart.isAfter(rs)) {
          newRanges.add((rs, pStart.isBefore(re) ? pStart : re));
        }
        // Découpe à droite
        if (pEnd.isBefore(re)) {
          newRanges.add((pEnd.isAfter(rs) ? pEnd : rs, re));
        }
      }

      ranges = newRanges;
    }

    // Éliminer ranges inversés / vides
    return ranges.where((r) => r.$2.isAfter(r.$1)).toList();
  }
}

// Petit alias privé pour réduire le bruit
typedef _D = DateTime;
