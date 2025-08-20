import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/database_service.dart';
import 'models/activity.dart';

final dbProvider = Provider<DatabaseService>((ref) => DatabaseService());

// La liste des activités (FutureProvider)
final activitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final db = ref.watch(dbProvider);
  return db.getAllActivities(); // <- assure-toi que cette méthode existe côté service
});
