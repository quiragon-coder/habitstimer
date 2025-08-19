import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import 'activity_detail_page.dart';
import '../widgets/activity_controls.dart';

class ActivitiesListPage extends ConsumerStatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  ConsumerState<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends ConsumerState<ActivitiesListPage> {
  final db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits Timer'),
        actions: [
          IconButton(onPressed: ()=> Navigator.pushNamed(context, '/heatmap'), icon: const Icon(Icons.grid_on)),
          IconButton(onPressed: ()=> Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.settings)),
        ],
      ),
      body: activitiesAsync.when(
        data: (items){
          if (items.isEmpty) {
            return const Center(child: Text('Ajoute une activité avec le +'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i){
              final a = items[i];
              return Card(
                child: ListTile(
                  title: Text(a.name),
                  subtitle: FutureBuilder<int>(
                    future: db.minutesForWeek(DateTime.now(), a.id!),
                    builder: (c, s) => Text('Semaine: ${s.data ?? 0} min' + (a.goalMinutesPerWeek!=null ? ' / ${a.goalMinutesPerWeek} min' : '')),
                  ),
                  onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> ActivityDetailPage(activity: a))),
                  trailing: ActivityControls(activityId: a.id!),
                ),
              );
            },
          );
        },
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e, st)=> Center(child: Text('Erreur: $e'))
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final a = await _askNewActivity(context);
          if (a == null) return;
          await db.insertActivity(a);
          ref.refresh(activitiesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<Activity?> _askNewActivity(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (c){
        final ctrl = TextEditingController();
        double weekMin = 300; // 5h
        double dayMin = 60;
        double daysPerWeek = 3;
        return StatefulBuilder(
          builder: (c, setState) => AlertDialog(
            title: const Text('Nouvelle activité'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nom')),
                  const SizedBox(height: 12),
                  Row(children: [const Text('Objectif h/sem'), Expanded(child: Slider(min:0, max:1200, divisions:120, value: weekMin, label: '${(weekMin/60).toStringAsFixed(1)}h', onChanged: (v)=> setState(()=> weekMin=v)))]),
                  Row(children: [const Text('Jours/sem'), Expanded(child: Slider(min:0, max:7, divisions:7, value: daysPerWeek, label: daysPerWeek.toStringAsFixed(0), onChanged: (v)=> setState(()=> daysPerWeek=v)))]),
                  Row(children: [const Text('Objectif h/jour'), Expanded(child: Slider(min:0, max:600, divisions:120, value: dayMin, label: '${(dayMin/60).toStringAsFixed(1)}h', onChanged: (v)=> setState(()=> dayMin=v)))]),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: ()=> Navigator.pop(c), child: const Text('Annuler')),
              FilledButton(onPressed: ()=> Navigator.pop(c, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()), child: const Text('Créer')),
            ],
          ),
        );
      }
    );
    if (name==null) return null;
    return Activity(
      name: name,
      goalMinutesPerWeek: 300,
      goalDaysPerWeek: 3,
      goalMinutesPerDay: 60,
    );
  }
}
