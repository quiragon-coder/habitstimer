// imports utiles en haut du fichier
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Exemple d'initialisation (si pas déjà fait)
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'habits_timer.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color INTEGER,
            goalHoursPerWeek REAL,
            goalDaysPerWeek INTEGER,
            goalHoursPerDay REAL
          );
        ''');
        await d.execute('''
          CREATE TABLE sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activityId INTEGER NOT NULL,
            startAt INTEGER NOT NULL,
            endAt INTEGER,
            FOREIGN KEY(activityId) REFERENCES activities(id)
          );
        ''');
        await d.execute('''
          CREATE TABLE pauses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionId INTEGER NOT NULL,
            startAt INTEGER NOT NULL,
            endAt INTEGER,
            FOREIGN KEY(sessionId) REFERENCES sessions(id)
          );
        ''');
      },
    );
    return _db!;
  }

  // ---------- ACTIVITIES ----------
  Future<int> insertActivity(Activity a) async {
    final d = await db;
    final id = await d.insert('activities', a.toMap());
    return id;
  }

  Future<int> updateActivity(Activity a) async {
    final d = await db;
    if (a.id == null) throw StateError('updateActivity: id null');
    return await d.update('activities', a.toMap(), where: 'id=?', whereArgs: [a.id]);
  }

  Future<List<Activity>> getActivities() async {
    final d = await db;
    final rows = await d.query('activities', orderBy: 'id DESC');
    return rows.map(Activity.fromMap).toList();
  }

  // ---------- SESSIONS ----------
  Future<int> startSession(int activityId) async {
    final d = await db;
    // si une session active existe déjà pour cette activité, on la reprend
    final running = await getRunningSession(activityId);
    if (running != null) return running.id!;

    final now = DateTime.now().millisecondsSinceEpoch;
    return await d.insert('sessions', {
      'activityId': activityId,
      'startAt': now,
      'endAt': null,
    });
  }

  Future<void> togglePause(int sessionId) async {
    final d = await db;
    // pause ouverte ?
    final open = await d.query('pauses',
        where: 'sessionId=? AND endAt IS NULL', whereArgs: [sessionId], limit: 1);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (open.isNotEmpty) {
      // reprendre
      final id = open.first['id'] as int;
      await d.update('pauses', {'endAt': now}, where: 'id=?', whereArgs: [id]);
    } else {
      // mettre en pause
      await d.insert('pauses', {
        'sessionId': sessionId,
        'startAt': now,
        'endAt': null,
      });
    }
  }

  Future<void> stopSession(int sessionId) async {
    final d = await db;
    // fermer une pause ouverte éventuelle
    final open = await d.query('pauses',
        where: 'sessionId=? AND endAt IS NULL', whereArgs: [sessionId], limit: 1);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (open.isNotEmpty) {
      final id = open.first['id'] as int;
      await d.update('pauses', {'endAt': now}, where: 'id=?', whereArgs: [id]);
    }
    // arrêter session
    await d.update('sessions', {'endAt': now}, where: 'id=?', whereArgs: [sessionId]);
  }

  Future<Session?> getRunningSession(int activityId) async {
    final d = await db;
    final rows = await d.query('sessions',
        where: 'activityId=? AND endAt IS NULL', whereArgs: [activityId], limit: 1);
    if (rows.isEmpty) return null;
    return Session.fromMap(rows.first);
  }

  // Minutes actives pour une semaine (signature compatible avec tes appels)
  Future<int> minutesForWeek(DateTime anyDayInWeek, int activityId) async {
    final monday = anyDayInWeek.subtract(Duration(days: (anyDayInWeek.weekday - 1)));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));

    final sessions = await getSessionsBetween(start, end, activityId: activityId);
    int totalMs = 0;
    for (final s in sessions) {
      final startAt = DateTime.fromMillisecondsSinceEpoch(s.startAt);
      final endAt = DateTime.fromMillisecondsSinceEpoch(s.endAt ?? DateTime.now().millisecondsSinceEpoch);
      final active = await _activeDurationForSession(s.id!);
      totalMs += active.inMilliseconds;
    }
    return (totalMs / 60000).round();
  }

  Future<List<Session>> getSessionsBetween(DateTime start, DateTime end, {int? activityId}) async {
    final d = await db;
    final where = StringBuffer('startAt>=? AND startAt<?');
    final args = <Object?>[start.millisecondsSinceEpoch, end.millisecondsSinceEpoch];
    if (activityId != null) {
      where.write(' AND activityId=?');
      args.add(activityId);
    }
    final rows = await d.query('sessions', where: where.toString(), whereArgs: args, orderBy: 'startAt DESC');
    return rows.map(Session.fromMap).toList();
  }

  // durée active d'une session (soustrait les pauses)
  Future<Duration> _activeDurationForSession(int sessionId) async {
    final d = await db;
    final row = (await d.query('sessions', where: 'id=?', whereArgs: [sessionId], limit: 1)).first;
    final startAt = row['startAt'] as int;
    final endAt = (row['endAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch;

    final pauses = await d.query('pauses', where: 'sessionId=?', whereArgs: [sessionId]);
    int pausedMs = 0;
    for (final p in pauses) {
      final ps = p['startAt'] as int;
      final pe = (p['endAt'] as int?) ?? endAt;
      pausedMs += (pe - ps);
    }
    final totalMs = (endAt - startAt) - pausedMs;
    return Duration(milliseconds: totalMs.clamp(0, 1 << 31));
  }
}
