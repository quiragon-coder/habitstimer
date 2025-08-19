import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/activity.dart';
import '../models/session.dart';
import '../models/pause.dart';

class DatabaseService {
  static Database? _db;

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
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE activities(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          goal_minutes_per_week INTEGER,
          goal_days_per_week INTEGER,
          goal_minutes_per_day INTEGER
        );
        ''');
        await db.execute('''
        CREATE TABLE sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_id INTEGER NOT NULL,
          start_at TEXT NOT NULL,
          end_at TEXT,
          FOREIGN KEY(activity_id) REFERENCES activities(id) ON DELETE CASCADE
        );
        ''');
        await db.execute('''
        CREATE TABLE pauses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          start_at TEXT NOT NULL,
          end_at TEXT,
          FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE
        );
        ''');
      },
    );
  }

  Future<void> _maybeSeed() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM activities')) ?? 0;
    if (count > 0) return;
    try {
      final raw = await rootBundle.loadString('assets/fixtures.json');
      final list = json.decode(raw) as List<dynamic>;
      for (final a in list) {
        final activity = Activity(
          name: a['name'] as String,
          goalMinutesPerWeek: a['goalMinutesPerWeek'] as int?,
          goalDaysPerWeek: a['goalDaysPerWeek'] as int?,
          goalMinutesPerDay: a['goalMinutesPerDay'] as int?,
        );
        final id = await insertActivity(activity);
        final sessions = a['sessions'] as List<dynamic>? ?? [];
        for (final s in sessions) {
          await _insertSessionMap({
            'activity_id': id,
            'start_at': s['start'] as String,
            'end_at': s['end'],
          });
        }
      }
    } catch (_) {
      // ignore seed errors
    }
  }

  // Activities
  Future<int> insertActivity(Activity a) async {
    final db = await database;
    final id = await db.insert('activities', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<int> updateActivity(Activity a) async {
    final db = await database;
    return db.update('activities', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<List<Activity>> getActivities() async {
    final db = await database;
    await _maybeSeed();
    final rows = await db.query('activities', orderBy: 'id DESC');
    return rows.map(Activity.fromMap).toList();
  }

  // Sessions
  Future<int> startSession(int activityId) async {
    final db = await database;
    // close existing running session for this activity
    final running = await getRunningSession(activityId);
    if (running != null) {
      await stopSessionByActivity(activityId);
    }
    return await _insertSessionMap({
      'activity_id': activityId,
      'start_at': DateTime.now().toIso8601String(),
      'end_at': null,
    });
  }

  Future<int> _insertSessionMap(Map<String, Object?> map) async {
    final db = await database;
    return db.insert('sessions', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Session?> getRunningSession(int activityId) async {
    final db = await database;
    final rows = await db.query('sessions',
      where: 'activity_id = ? AND end_at IS NULL',
      whereArgs: [activityId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Session.fromMap(rows.first);
  }

  Future<void> togglePauseByActivity(int activityId) async {
    // Simplified: if running, toggle a pause record; for now we just no-op to keep UI flowing.
    // You can extend to actually subtract paused durations from stats.
    final s = await getRunningSession(activityId);
    if (s == null) return;
    final db = await database;
    // Check last open pause
    final open = await db.query('pauses', where: 'session_id = ? AND end_at IS NULL', whereArgs: [s.id], orderBy: 'id DESC', limit: 1);
    if (open.isEmpty) {
      await db.insert('pauses', {
        'session_id': s.id,
        'start_at': DateTime.now().toIso8601String(),
        'end_at': null,
      });
    } else {
      final pid = open.first['id'] as int;
      await db.update('pauses', {'end_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [pid]);
    }
  }

  Future<void> stopSessionByActivity(int activityId) async {
    final db = await database;
    final s = await getRunningSession(activityId);
    if (s == null) return;
    await db.update('sessions', {'end_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [s.id]);
    // close open pause if any
    await db.update('pauses', {'end_at': DateTime.now().toIso8601String()}, where: 'session_id = ? AND end_at IS NULL', whereArgs: [s.id]);
  }

  // Stats
  Future<int> minutesForWeek(DateTime day, int activityId) async {
    final db = await database;
    final monday = day.subtract(Duration(days: (day.weekday + 6) % 7));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final rows = await db.query('sessions',
      where: 'activity_id = ? AND start_at < ? AND (end_at IS NULL OR end_at > ?)',
      whereArgs: [activityId, weekEnd.toIso8601String(), weekStart.toIso8601String()],
    );
    int minutes = 0;
    final now = DateTime.now();
    for (final r in rows) {
      final start = DateTime.parse(r['start_at'] as String);
      final endStr = r['end_at'] as String?;
      final end = endStr == null ? now : DateTime.parse(endStr);
      final from = start.isBefore(weekStart) ? weekStart : start;
      final to = end.isAfter(weekEnd) ? weekEnd : end;
      if (to.isAfter(from)) {
        minutes += to.difference(from).inMinutes;
      }
    }
    return minutes;
  }

  Future<List<int>> hourlyActiveMinutes(DateTime day, {required int activityId}) async {
    final db = await database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query('sessions',
      where: 'activity_id = ? AND start_at < ? AND (end_at IS NULL OR end_at > ?)',
      whereArgs: [activityId, end.toIso8601String(), start.toIso8601String()],
    );
    final buckets = List<int>.filled(24, 0);
    final now = DateTime.now();
    for (final r in rows) {
      DateTime s = DateTime.parse(r['start_at'] as String);
      DateTime e = (r['end_at'] as String?) == null ? now : DateTime.parse(r['end_at'] as String);
      if (s.isBefore(start)) s = start;
      if (e.isAfter(end)) e = end;
      if (!e.isAfter(s)) continue;
      var cur = s;
      while (cur.isBefore(e)) {
        final hourEnd = DateTime(cur.year, cur.month, cur.day, cur.hour).add(const Duration(hours: 1));
        final sliceEnd = e.isBefore(hourEnd) ? e : hourEnd;
        final mins = sliceEnd.difference(cur).inMinutes;
        if (mins > 0) buckets[cur.hour] += mins;
        cur = sliceEnd;
      }
    }
    return buckets;
  }

  // Export/Import/Reset
  Future<Map<String, Object?>> exportJson() async {
    final db = await database;
    final acts = await db.query('activities');
    final sessions = await db.query('sessions');
    final pauses = await db.query('pauses');
    return {'activities': acts, 'sessions': sessions, 'pauses': pauses};
  }

  Future<void> importJson(Map<String, Object?> map, {bool reset = false}) async {
    final db = await database;
    if (reset) {
      await resetDatabase();
    }
    final acts = (map['activities'] as List).cast<Map>().cast<Map<String, Object?>>();
    for (final a in acts) {
      final data = Map<String, Object?>.from(a);
      data.remove('id');
      await db.insert('activities', data, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    final sessions = (map['sessions'] as List).cast<Map>().cast<Map<String, Object?>>();
    for (final s in sessions) {
      final data = Map<String, Object?>.from(s);
      data.remove('id');
      await db.insert('sessions', data, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    final pauses = (map['pauses'] as List).cast<Map>().cast<Map<String, Object?>>();
    for (final pz in pauses) {
      final data = Map<String, Object?>.from(pz);
      data.remove('id');
      await db.insert('pauses', data, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> resetDatabase() async {
    final path = await databasePath();
    await _db?.close();
    _db = null;
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
    await _open();
  }
}
