// lib/services/database_service.dart
//
// Version mock en mémoire pour faire tourner l'app
// sans erreur de compilation et avec les méthodes
// attendues par les pages (UI + providers + widgets).

import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../models/activity.dart';
import '../models/session.dart' as ms;
import '../models/pause.dart' as mp;

class DatabaseService {
  // --- Stockage en mémoire (mock) ---
  final List<Activity> _activities = [];
  final List<ms.Session> _sessions = [];
  final List<mp.Pause> _pauses = [];

  int _nextActivityId = 1;
  int _nextSessionId = 1;
  int _nextPauseId = 1;

  // ---------------------------------------------------
  // ACTIVITÉS
  // ---------------------------------------------------

  /// Historique : certains endroits appellent `getActivities()`
  /// (erreur précédente dans providers.dart). On le fournit
  /// et on l'aligne sur `getAllActivities()`.
  Future<List<Activity>> getActivities() async => getAllActivities();

  Future<List<Activity>> getAllActivities() async {
    // on renvoie une copie défensive
    return List<Activity>.from(_activities);
  }

  /// Ajout d’une activité (passe un `Activity`; si tu avais un String avant,
  /// construis un Activity côté UI : Activity(name: "Nouvelle activité")).
  Future<int> addActivity(Activity a) async {
    final withId = a.copyWith?.call(id: _nextActivityId) ??
        Activity(
          id: _nextActivityId,
          name: a.name,
          // Valeurs facultatives : garde null si non présentes
          emoji: a.emoji,
          colorHex: a.colorHex,
          goalMinutesPerWeek: a.goalMinutesPerWeek,
          goalDaysPerWeek: a.goalDaysPerWeek,
          goalMinutesPerDay: a.goalMinutesPerDay,
        );

    _activities.add(withId);
    _nextActivityId++;
    return withId.id!;
  }

  /// Petit helper si tu veux créer rapidement par nom (si jamais tu le ré-utilises)
  Future<int> addActivityByName(String name) async {
    return addActivity(Activity(name: name));
  }

  Future<int> deleteActivity(int id) async {
    final before = _activities.length;
    _activities.removeWhere((a) => a.id == id);
    // supprime aussi les sessions liées
    _sessions.removeWhere((s) => s.activityId == id);
    _pauses.removeWhere((p) {
      final owning = _sessions.any((s) => s.id == p.sessionId);
      return !owning; // si plus de session, supprime pause orpheline
    });
    return before - _activities.length;
  }

  // ---------------------------------------------------
  // SESSIONS (start / pause / stop)
  // ---------------------------------------------------

  /// Démarre une session pour une activité. Stoppe la précédente si ouverte.
  Future<ms.Session> startSession(int activityId) async {
    // si une session court pour cette activité, on la stoppe
    final running = await getRunningSession(activityId);
    if (running != null) {
      await stopSession(running.id, activityId);
    }

    final session = ms.Session(
      id: _nextSessionId++,
      activityId: activityId,
      startAt: DateTime.now(),
      endAt: null,
      // si ton modèle n’a pas `pauses`, on gère à part (_pauses).
      // s'il l’a, ça ne dérange pas de passer [].
      pauses: const [],
    );
    _sessions.add(session);
    return session;
  }

  /// Retourne la session en cours pour une activité (s'il y en a une).
  Future<ms.Session?> getRunningSession(int activityId) async {
    try {
      return _sessions.firstWhere(
            (s) => s.activityId == activityId && s.endAt == null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Pause/reprise par activityId (utilisé par activity_controls.dart).
  Future<void> togglePauseByActivity(int activityId) async {
    final running = await getRunningSession(activityId);
    if (running == null) return;
    await togglePause(running.id, activityId);
  }

  /// Stop par activityId (utilisé par activity_controls.dart).
  Future<void> stopSessionByActivity(int activityId) async {
    final running = await getRunningSession(activityId);
    if (running == null) return;
    await stopSession(running.id, activityId);
  }

  /// Pause / resume : si une pause ouverte existe -> on la ferme, sinon on ouvre.
  /// On accepte sessionId et/ou activityId pour coller aux signatures déjà utilisées.
  Future<void> togglePause(int? sessionId, int activityId) async {
    final session = sessionId != null
        ? _sessions.firstWhere((s) => s.id == sessionId, orElse: () => throw StateError('Session introuvable'))
        : (await getRunningSession(activityId)) ??
        (throw StateError('Aucune session en cours pour activityId=$activityId'));

    // si session déjà terminée, ne rien faire
    if (session.endAt != null) return;

    // cherche une pause ouverte
    final openPause = _pauses.cast<mp.Pause?>().firstWhere(
          (p) => p != null && p.sessionId == session.id && p.endAt == null,
      orElse: () => null,
    );

    if (openPause == null) {
      // on ouvre une nouvelle pause
      final pause = mp.Pause(
        id: _nextPauseId++,
        sessionId: session.id!,
        startAt: DateTime.now(),
        endAt: null,
      );
      _pauses.add(pause);
    } else {
      // on ferme la pause
      final idx = _pauses.indexWhere((p) => p.id == openPause.id);
      if (idx >= 0) {
        _pauses[idx] = mp.Pause(
          id: openPause.id,
          sessionId: openPause.sessionId,
          startAt: openPause.startAt,
          endAt: DateTime.now(),
        );
      }
    }
  }

  /// Stoppe la session : ferme une éventuelle pause ouverte + fixe endAt.
  Future<void> stopSession(int? sessionId, int activityId) async {
    final session = sessionId != null
        ? _sessions.firstWhere((s) => s.id == sessionId, orElse: () => throw StateError('Session introuvable'))
        : (await getRunningSession(activityId)) ??
        (throw StateError('Aucune session en cours pour activityId=$activityId'));

    if (session.endAt != null) return;

    // ferme pause ouverte
    final openPause = _pauses.cast<mp.Pause?>().firstWhere(
          (p) => p != null && p.sessionId == session.id && p.endAt == null,
      orElse: () => null,
    );
    if (openPause != null) {
      final idx = _pauses.indexWhere((p) => p.id == openPause.id);
      if (idx >= 0) {
        _pauses[idx] = mp.Pause(
          id: openPause.id,
          sessionId: openPause.sessionId,
          startAt: openPause.startAt,
          endAt: DateTime.now(),
        );
      }
    }

    // marque la fin de la session
    final i = _sessions.indexWhere((s) => s.id == session.id);
    if (i >= 0) {
      _sessions[i] = ms.Session(
        id: session.id,
        activityId: session.activityId,
        startAt: session.startAt,
        endAt: DateTime.now(),
        pauses: const [], // on garde les pauses séparées (_pauses)
      );
    }
  }

  // ---------------------------------------------------
  // REQUÊTES / STATS
  // ---------------------------------------------------

  /// Sessions entre deux dates (filtrable par activité).
  Future<List<ms.Session>> getSessionsBetween(
      DateTime start,
      DateTime end, {
        int? activityId,
      }) async {
    final list = _sessions.where((s) {
      if (activityId != null && s.activityId != activityId) return false;
      // garde les sessions qui chevauchent l'intervalle [start, end]
      final sEnd = s.endAt ?? DateTime.now();
      final overlap = s.startAt.isBefore(end) && sEnd.isAfter(start);
      return overlap;
    }).toList();

    return list;
  }

  /// Minutes actives sur un jour (hors pauses).
  Future<int> dailyActiveMinutes(DateTime day, int activityId) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final sessions = await getSessionsBetween(start, end, activityId: activityId);
    int minutes = 0;

    for (final s in sessions) {
      final sStart = s.startAt.isBefore(start) ? start : s.startAt;
      final sEnd = (s.endAt ?? DateTime.now()).isAfter(end) ? end : (s.endAt ?? DateTime.now());

      final paused = _pauses
          .where((p) => p.sessionId == s.id)
          .fold<int>(0, (acc, p) {
        final pStart = p.startAt.isBefore(start) ? start : p.startAt;
        final pEnd = (p.endAt ?? DateTime.now()).isAfter(end) ? end : (p.endAt ?? DateTime.now());
        final diff = pEnd.difference(pStart).inMinutes;
        return acc + (diff > 0 ? diff : 0);
      });

      final dur = sEnd.difference(sStart).inMinutes - paused;
      minutes += dur > 0 ? dur : 0;
    }

    return minutes;
  }

  /// Minutes hebdo (lundi → dimanche) pour une activité.
  Future<int> minutesForWeek(DateTime anyDayInWeek, int activityId) async {
    final monday = anyDayInWeek.subtract(Duration(days: (anyDayInWeek.weekday + 6) % 7));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));

    final sessions = await getSessionsBetween(start, end, activityId: activityId);

    int total = 0;
    for (final s in sessions) {
      final sStart = s.startAt.isBefore(start) ? start : s.startAt;
      final sEnd = (s.endAt ?? DateTime.now()).isAfter(end) ? end : (s.endAt ?? DateTime.now());

      final paused = _pauses
          .where((p) => p.sessionId == s.id)
          .fold<int>(0, (acc, p) {
        final pStart = p.startAt.isBefore(start) ? start : p.startAt;
        final pEnd = (p.endAt ?? DateTime.now()).isAfter(end) ? end : (p.endAt ?? DateTime.now());
        final diff = pEnd.difference(pStart).inMinutes;
        return acc + (diff > 0 ? diff : 0);
      });

      final dur = sEnd.difference(sStart).inMinutes - paused;
      total += dur > 0 ? dur : 0;
    }
    return total;
  }

  /// Minutes par heure sur une journée (24 buckets).
  Future<List<int>> hourlyActiveMinutes(DateTime day, {required int activityId}) async {
    final buckets = List<int>.filled(24, 0);
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final sessions = await getSessionsBetween(start, end, activityId: activityId);

    for (final s in sessions) {
      final sStart = s.startAt.isBefore(start) ? start : s.startAt;
      final sEnd = (s.endAt ?? DateTime.now()).isAfter(end) ? end : (s.endAt ?? DateTime.now());

      // découpe par heure
      var cursor = sStart;
      while (cursor.isBefore(sEnd)) {
        final hourEnd = DateTime(cursor.year, cursor.month, cursor.day, cursor.hour).add(const Duration(hours: 1));
        final segEnd = sEnd.isBefore(hourEnd) ? sEnd : hourEnd;

        // minutes brutes sur le segment
        var segMinutes = segEnd.difference(cursor).inMinutes;

        // retire les pauses qui chevauchent ce segment
        final pauses = _pauses.where((p) => p.sessionId == s.id);
        for (final p in pauses) {
          final pStart = p.startAt.isBefore(cursor) ? cursor : p.startAt;
          final pEnd = (p.endAt ?? DateTime.now()).isAfter(segEnd) ? segEnd : (p.endAt ?? DateTime.now());
          final overlap = pEnd.difference(pStart).inMinutes;
          if (overlap > 0) segMinutes -= overlap;
        }

        final idx = cursor.hour;
        if (segMinutes > 0 && idx >= 0 && idx < 24) {
          buckets[idx] += segMinutes;
        }

        cursor = hourEnd;
      }
    }
    return buckets;
  }

  // ---------------------------------------------------
  // OUTILS (export / import / reset / chemin)
  // ---------------------------------------------------

  Future<String> databasePath() async {
    // Mock : chemin fictif utile pour l’écran Settings
    return '/mock/path/habits_timer.db';
  }

  Future<String> exportJson() async {
    final data = {
      'activities': _activities.map((a) => a.toMap()).toList(),
      'sessions': _sessions.map((s) {
        return {
          'id': s.id,
          'activityId': s.activityId,
          'startAt': s.startAt.toIso8601String(),
          'endAt': s.endAt?.toIso8601String(),
        };
      }).toList(),
      'pauses': _pauses.map((p) {
        return {
          'id': p.id,
          'sessionId': p.sessionId,
          'startAt': p.startAt.toIso8601String(),
          'endAt': p.endAt?.toIso8601String(),
        };
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importJson(String json) async {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      _activities
        ..clear()
        ..addAll((map['activities'] as List<dynamic>)
            .map((m) => Activity.fromMap?.call(Map<String, dynamic>.from(m)) ?? Activity(name: m['name'] ?? '')))
      ;

      _sessions
        ..clear()
        ..addAll((map['sessions'] as List<dynamic>).map((m) {
          final mm = Map<String, dynamic>.from(m);
          return ms.Session(
            id: mm['id'] as int?,
            activityId: mm['activityId'] as int,
            startAt: DateTime.parse(mm['startAt'] as String),
            endAt: mm['endAt'] != null ? DateTime.parse(mm['endAt'] as String) : null,
            pauses: const [],
          );
        }));

      _pauses
        ..clear()
        ..addAll((map['pauses'] as List<dynamic>).map((m) {
          final mm = Map<String, dynamic>.from(m);
          return mp.Pause(
            id: mm['id'] as int?,
            sessionId: mm['sessionId'] as int,
            startAt: DateTime.parse(mm['startAt'] as String),
            endAt: mm['endAt'] != null ? DateTime.parse(mm['endAt'] as String) : null,
          );
        }));

      // recalc IDs
      _nextActivityId = (_activities.map((e) => e.id ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _nextSessionId = (_sessions.map((e) => e.id ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
      _nextPauseId = (_pauses.map((e) => e.id ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1;
    } catch (e) {
      if (kDebugMode) {
        // en debug, on log l’erreur d’import
        // (évite un crash si JSON pas conforme)
        // print(e);
      }
    }
  }

  Future<void> resetDatabase() async {
    _activities.clear();
    _sessions.clear();
    _pauses.clear();
    _nextActivityId = 1;
    _nextSessionId = 1;
    _nextPauseId = 1;
  }
}
