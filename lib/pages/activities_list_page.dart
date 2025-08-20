import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits_timer/models/activity.dart';
import 'package:habits_timer/pages/activity_detail_page.dart';
import 'package:habits_timer/pages/create_activity_page.dart';
import 'package:habits_timer/providers.dart';
import 'package:habits_timer/services/database_service.dart';
import 'package:habits_timer/widgets/activity_controls.dart';

class ActivitiesListPage extends ConsumerStatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  ConsumerState<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends ConsumerState<ActivitiesListPage> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits Timer'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/heatmap'),
            icon: const Icon(Icons.grid_on),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: activitiesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("Ajoute une activité avec le +"));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final a = items[i];
              return Card(
                child: ListTile(
                  leading: Text(a.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(a.name),
                  subtitle: FutureBuilder<int>(
                    future: _db.minutesForWeek(DateTime.now(), a.id!),
                    builder: (_, snap) {
                      final m = snap.data ?? 0;
                      final g = a.goalMinutesPerWeek;
                      final text = g == null ? 'Semaine: $m min' : 'Semaine: $m / $g min';
                      return Text(text);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ActivityDetailPage(activity: a)),
                    ).then((_) => ref.refresh(activitiesProvider));
                  },
                  trailing: ActivityControls(activity: a),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<Activity?>(
            context,
            MaterialPageRoute(builder: (_) => const CreateActivityPage()),
          );
          if (created != null) {
            await _db.addActivity(created);
            if (mounted) ref.refresh(activitiesProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
