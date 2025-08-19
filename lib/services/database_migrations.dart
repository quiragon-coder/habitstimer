import 'package:sqflite/sqflite.dart';

Future<void> applyMigrations(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
  final res = await db.rawQuery('PRAGMA user_version');
  final int currentVersion = (res.first['user_version'] as int?) ?? 0;

  if (currentVersion < 1) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        goalMinutesPerWeek INTEGER,
        goalDaysPerWeek INTEGER,
        goalMinutesPerDay INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activityId INTEGER NOT NULL,
        startAt TEXT NOT NULL,
        endAt   TEXT,
        FOREIGN KEY(activityId) REFERENCES activities(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pauses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER NOT NULL,
        startAt   TEXT NOT NULL,
        endAt     TEXT,
        FOREIGN KEY(sessionId) REFERENCES sessions(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_activity ON sessions(activityId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_start ON sessions(startAt)');
    await db.execute('PRAGMA user_version = 1');
  }

  // Future versions: add more migrations and bump user_version
}
