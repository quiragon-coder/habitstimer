import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../widgets/daily_bars.dart';

class ActivityDetailPage extends StatefulWidget {
  final Activity activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final db = DatabaseService();
  late DateTime selectedDay;
  Session? running;

  @override
  void initState() {
    super.initState();
    selectedDay = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    running = await db.getRunningSession(widget.activity.id);
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    return Scaffold(
      appBar: AppBar(title: Text(a.name)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(child: FutureBuilder<int>(
                future: db.minutesForWeek(DateTime.now(), a.id),
                builder: (c, s) => Card(child: ListTile(title: const Text('Semaine'), subtitle: Text('${s.data ?? 0} min'))),
              )),
              const SizedBox(width: 8),
              Expanded(child: FutureBuilder<int>(
                future: db.minutesForDay(DateTime.now(), a.id),
                builder: (c, s) => Card(child: ListTile(title: const Text('Aujourd’hui'), subtitle: Text('${s.data ?? 0} min'))),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Par heure (${DateFormat('yMMMd').format(selectedDay)})', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FutureBuilder<List<int>>(
                    future: db.hourlyActiveMinutes(selectedDay, activityId: a.id),
                    builder: (c, s) => s.hasData ? DailyBars(hourlyMinutes: s.data!) : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(onPressed: (){ setState(()=> selectedDay = selectedDay.subtract(const Duration(days: 1))); }, icon: const Icon(Icons.chevron_left)),
                      Text(DateFormat('EEEE d MMM').format(selectedDay)),
                      IconButton(onPressed: (){ setState(()=> selectedDay = selectedDay.add(const Duration(days: 1))); }, icon: const Icon(Icons.chevron_right)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historique (7 jours)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Session>>(
                    future: db.getSessionsBetween(DateTime.now().subtract(const Duration(days: 7)), DateTime.now(), activityId: a.id),
                    builder: (c, s) {
                      if (!s.hasData) return const Center(child: CircularProgressIndicator());
                      final items = s.data!;
                      if (items.isEmpty) return const Text('Aucune session.');
                      return Column(
                        children: items.map((e){
                          final dur = e.endAt==null ? const Duration() : e.endAt!.difference(e.startAt);
                          return ListTile(
                            leading: const Icon(Icons.timer),
                            title: Text('${DateFormat.Hm().format(e.startAt)} → ${e.endAt==null ? '...' : DateFormat.Hm().format(e.endAt!)}'),
                            subtitle: Text('${dur.inMinutes} min'),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(child: FilledButton(onPressed: () async { await db.togglePause(running?.id, a.id); await _load(); }, child: const Text('Pause / Reprendre'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () async { await db.stopSession(running?.id, a.id); await _load(); }, child: const Text('Arrêter'))),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await db.startSession(a.id!);
          await _load();
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
