import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import 'create_activity_page.dart';

class ActivitiesListPage extends ConsumerWidget {
  const ActivitiesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final activities = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: activities.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Ajoute une activité avec le +'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final Activity a = items[i];
              return Card(
                child: ListTile(
                  leading: Text(a.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(a.name),
                  subtitle: Text('Couleur: #${a.color.toRadixString(16).padLeft(8, '0').toUpperCase()}'),
                  onTap: () {
                    // plus tard: aller au détail
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateActivityPage()),
          );
          if (created == true) {
            // recharger la liste
            ref.invalidate(activitiesProvider); // ou ref.refresh(activitiesProvider)
          }
        },
      ),
    );
  }
}
