import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../providers.dart';
import '../services/database_service.dart';
import '../widgets/activity_controls.dart';
import '../widgets/hourly_bars.dart';
import '../widgets/daily_bars.dart';

class ActivityDetailPage extends ConsumerWidget {
  final Activity activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(activity.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contrôles'),
                  ActivityControls(activity: activity),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aujourd'hui (minutes/heure)'),
                  FutureBuilder<List<int>>(
                    future: db.hourlyActiveMinutes(today, activityId: activity.id!),
                    builder: (_, snap) => snap.hasData
                      ? HourlyBars(data: snap.data!)
                      : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('7 derniers jours (minutes/jour)'),
                  FutureBuilder<Map<DateTime,int>>(
                    future: () async {
                      final end = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
                      final start = end.subtract(const Duration(days: 7));
                      return db.dailyActiveMinutes(start, end, activityId: activity.id);
                    }(),
                    builder: (_, snap) => snap.hasData
                      ? DailyBars(data: snap.data!)
                      : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
