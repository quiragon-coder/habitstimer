import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/activity.dart';
import 'create_activity_page.dart';
import 'activity_detail_page.dart';

class ActivitiesListPage extends StatefulWidget {
  @override
  _ActivitiesListPageState createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends State<ActivitiesListPage> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mes activités")),
      body: FutureBuilder<List<Activity>>(
        future: _db.getActivities(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data!;
          if (activities.isEmpty) {
            return Center(child: Text("Ajoute une activité avec le +"));
          }

          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                color: Color(activity.color),
                child: ListTile(
                  leading: Text(
                    activity.emoji,
                    style: TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    activity.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _buildGoalsText(activity),
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailPage(activity: activity),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateActivityPage()),
          );
          if (result == true) setState(() {});
        },
        child: Icon(Icons.add),
      ),
    );
  }

  String _buildGoalsText(Activity activity) {
    final goals = <String>[];
    if (activity.goalMinutesPerDay != null) {
      goals.add("${activity.goalMinutesPerDay} min/jour");
    }
    if (activity.goalMinutesPerWeek != null) {
      goals.add("${activity.goalMinutesPerWeek} min/semaine");
    }
    if (activity.goalMinutesPerMonth != null) {
      goals.add("${activity.goalMinutesPerMonth} min/mois");
    }
    if (activity.goalMinutesPerYear != null) {
      goals.add("${activity.goalMinutesPerYear} min/an");
    }
    return goals.isEmpty ? "Aucun objectif" : goals.join(" • ");
  }
}
