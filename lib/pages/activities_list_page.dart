import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'activity_detail_page.dart';

class ActivitiesListPage extends StatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  State<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends State<ActivitiesListPage> {
  final _db = DatabaseService();

  Future<void> _createActivity() async {
    await _db.createActivity ("Nouvelle activité");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes activités"),
      ),
      body: FutureBuilder(
        future: _db.getActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Ajoute une activité avec le +"),
            );
          }
          final acts = snapshot.data!;
          return ListView.builder(
            itemCount: acts.length,
            itemBuilder: (context, i) {
              final activity = acts[i];
              return ListTile(
                title: Text(activity.name),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ActivityDetailPage(activity: activity),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createActivity,
        child: const Icon(Icons.add),
      ),
    );
  }
}
