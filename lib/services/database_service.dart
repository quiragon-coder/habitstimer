import '../models/activity.dart';
import '../models/session.dart';

class DatabaseService {
  final List<Activity> _activities = [];
  final List<Session> _sessions = [];

  // ---- Activities ----
  Future<List<Activity>> getAllActivities() async {
    return _activities;
  }

  Future<void> addActivity(Activity activity) async {
    _activities.add(activity);
  }

  // ---- Sessions ----
  Future<Session?> getRunningSession(int activityId) async {
    try {
      return _sessions.firstWhere(
            (s) => s.activityId == activityId && s.endAt == null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> startSession(int activityId) async {
    final session = Session(
      id: _sessions.length + 1,
      activityId: activityId,
      startAt: DateTime.now(),
    );
    _sessions.add(session);
  }

  Future<void> stopSessionByActivity(int activityId) async {
    final session = await getRunningSession(activityId);
    if (session == null) return;

    final updated = Session(
      id: session.id,
      activityId: session.activityId,
      startAt: session.startAt,
      endAt: DateTime.now(),
    );
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.add(updated);
  }

  Future<void> togglePauseByActivity(int activityId) async {
    print("TODO: toggle pause for activity $activityId");
  }
}
