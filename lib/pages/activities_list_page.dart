import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/activity.dart';

class ActivitiesListPage extends StatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  State<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends State<ActivitiesListPage> {
  final DatabaseService _db = DatabaseService();

  Future<void> _addActivity() async {
    final newActivity = Activity(
      id: DateTime.now().millisecondsSinceEpoch,
      name: "Nouvelle activité",
    );
    await _db.addActivity(newActivity);
    setState(() {}); // refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes activités")),
      body: FutureBuilder<List<Activity>>(
        future: _db.getAllActivities(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final activities = snapshot.data!;
          if (activities.isEmpty) {
            return const Center(child: Text("Ajoute une activité avec le +"));
          }

          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                title: Text(activity.name),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addActivity,
        child: const Icon(Icons.add),
      ),
    );
  }
}
