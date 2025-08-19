import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/activity.dart';
import '../models/session.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<String> databasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'habits_timer.db');
  }

  Future<Database> _open() async {
    final path = await databasePath();
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            goalMinutesPerWeek INTEGER,
            goalDaysPerWeek INTEGER,
            goalMinutesPerDay INTEGER,
            createdAt TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activityId INTEGER NOT NULL,
            startAt TEXT NOT NULL,
            endAt TEXT,
            FOREIGN KEY(activityId) REFERENCES activities(id) ON DELETE CASCADE
          );
        ''');
        await db.execute('''
          CREATE TABLE pauses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionId INTEGER NOT NULL,
            startAt TEXT NOT NULL,
            endAt TEXT,
            FOREIGN KEY(sessionId) REFERENCES sessions(id) ON DELETE CASCADE
          );
        ''');
      },
    );
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('pauses');
    await db.delete('sessions');
    await db.delete('activities');
  }

  // Activities
  Future<int> insertActivity(Activity a) async {
    final db = await database;
    return db.insert('activities', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateActivity(Activity a) async {
    final db = await database;
    return db.update('activities', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<List<Activity>> getActivities() async {
    final db = await database;
    final res = await db.query('activities', orderBy: 'createdAt DESC');
    return res.map((e) => Activity.fromMap(e)).toList();
  }

  // Sessions
  Future<Session?> getRunningSession({int? activityId}) async {
    final db = await database;
    final where = activityId != null ? 'activityId = ? AND endAt IS NULL' : 'endAt IS NULL';
    final whereArgs = activityId != null ? [activityId] : null;
    final res = await db.query('sessions', where: where, whereArgs: whereArgs, orderBy: 'startAt DESC', limit: 1);
    if (res.isEmpty) return null;
    return Session.fromMap(res.first);
  }

  Future<int> startSession(int activityId) async {
    final db = await database;
    final running = await getRunningSession(activityId: activityId);
    if (running != null) {
      return running.id!;
    }
    return db.insert('sessions', {
      'activityId': activityId,
      'startAt': DateTime.now().toIso8601String(),
      'endAt': null,
    });
  }

  Future<void> stopSessionByActivity(int activityId) async {
    final running = await getRunningSession(activityId: activityId);
    if (running == null) return;
    await stopSession(running.id!);
  }

  Future<void> stopSession(int sessionId) async {
    final db = await database;
    await db.update('sessions', {
      'endAt': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [sessionId]);
    // close any open pause
    final res = await db.query('pauses', where: 'sessionId = ? AND endAt IS NULL', whereArgs: [sessionId]);
    for (final row in res) {
      await db.update('pauses', {'endAt': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [row['id']]);
    }
  }

  Future<void> togglePauseByActivity(int activityId) async {
    final running = await getRunningSession(activityId: activityId);
    if (running == null) return;
    await togglePause(running.id!);
  }

  Future<void> togglePause(int sessionId) async {
    final db = await database;
    final open = await db.query('pauses', where: 'sessionId = ? AND endAt IS NULL', whereArgs: [sessionId], limit: 1);
    if (open.isEmpty) {
      await db.insert('pauses', {
        'sessionId': sessionId,
        'startAt': DateTime.now().toIso8601String(),
        'endAt': null,
      });
    } else {
      final id = open.first['id'] as int;
      await db.update('pauses', {'endAt': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    }
  }

  // Metrics
  Future<int> minutesForDay(DateTime day, int activityId) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _minutesBetween(start, end, activityId: activityId);
  }

  Future<int> minutesForWeek(DateTime anyDayInWeek, int activityId) async {
    final weekday = anyDayInWeek.weekday; // 1 Mon..7 Sun
    final start = DateTime(anyDayInWeek.year, anyDayInWeek.month, anyDayInWeek.day).subtract(Duration(days: weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _minutesBetween(start, end, activityId: activityId);
  }

  Future<List<int>> hourlyActiveMinutes(DateTime day, {required int activityId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final List<int> buckets = List.filled(24, 0);
    for (int h = 0; h < 24; h++) {
      final hs = DateTime(start.year, start.month, start.day, h);
      final he = hs.add(const Duration(hours: 1));
      buckets[h] = await _minutesBetween(hs, he, activityId: activityId);
    }
    return buckets;
  }

  Future<Map<DateTime, int>> dailyActiveMinutes(DateTime start, DateTime end, {int? activityId}) async {
    final Map<DateTime, int> out = {};
    var d = DateTime(start.year, start.month, start.day);
    while (d.isBefore(end)) {
      final m = await _minutesBetween(d, d.add(const Duration(days:1)), activityId: activityId);
      out[d] = m;
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  Future<List<Session>> getSessionsBetween(DateTime start, DateTime end, {int? activityId}) async {
    final db = await database;
    final where = StringBuffer('startAt < ? AND (endAt IS NULL OR endAt > ?)');
    final args = <Object?>[end.toIso8601String(), start.toIso8601String()];
    if (activityId != null) {
      where.write(' AND activityId = ?');
      args.add(activityId);
    }
    final res = await db.query('sessions', where: where.toString(), whereArgs: args, orderBy: 'startAt ASC');
    return res.map((e) => Session.fromMap(e)).toList();
  }

  Future<List<Pause>> _getPausesForSessions(List<int> sessionIds) async {
    if (sessionIds.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(sessionIds.length, '?').join(',');
    final res = await db.rawQuery('SELECT * FROM pauses WHERE sessionId IN ($placeholders) ORDER BY startAt ASC', sessionIds);
    return res.map((e) => Pause.fromMap(e)).toList();
  }

  static int _overlapMinutes(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    final start = aStart.isAfter(bStart) ? aStart : bStart;
    final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    if (!end.isAfter(start)) return 0;
    return end.difference(start).inMinutes;
  }

  Future<int> _minutesBetween(DateTime start, DateTime end, {int? activityId}) async {
    final sessions = await getSessionsBetween(start, end, activityId: activityId);
    final pauses = await _getPausesForSessions([for (final s in sessions) s.id!]);
    int total = 0;
    for (final s in sessions) {
      final sStart = s.startAt.isBefore(start) ? start : s.startAt;
      final sEnd = (s.endAt ?? end).isAfter(end) ? end : (s.endAt ?? end);
      if (!sEnd.isAfter(sStart)) continue;
      int minutes = sEnd.difference(sStart).inMinutes;
      for (final p in pauses.where((pp) => pp.sessionId == s.id)) {
        final pEnd = p.endAt ?? end;
        minutes -= _overlapMinutes(sStart, sEnd, p.startAt, pEnd);
      }
      if (minutes > 0) total += minutes;
    }
    return total;
  }

  // Export / Import
  Future<Map<String, dynamic>> exportJson() async {
    final db = await database;
    final activities = await db.query('activities');
    final sessions = await db.query('sessions');
    final pauses = await db.query('pauses');
    return {
      'activities': activities,
      'sessions': sessions,
      'pauses': pauses,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importJson(Map<String, Object?> map, {bool reset = false}) async {
    final db = await database;
    final batch = db.batch();
    if (reset) {
      batch.delete('pauses');
      batch.delete('sessions');
      batch.delete('activities');
    }
    final activities = (map['activities'] as List<dynamic>? ?? []).cast<Map>();
    final sessions = (map['sessions'] as List<dynamic>? ?? []).cast<Map>();
    final pauses = (map['pauses'] as List<dynamic>? ?? []).cast<Map>();
    for (final a in activities) {
      batch.insert('activities', Map<String, Object?>.from(a), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final s in sessions) {
      batch.insert('sessions', Map<String, Object?>.from(s), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final pz in pauses) {
      batch.insert('pauses', Map<String, Object?>.from(pz), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
