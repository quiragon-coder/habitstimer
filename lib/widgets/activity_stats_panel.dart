import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../providers_stats.dart';
import 'hourly_bars_chart.dart';
import 'weekly_bars_chart.dart';

class ActivityStatsPanel extends ConsumerWidget {
  final Activity activity;
  const ActivityStatsPanel({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = activity.id; // peut être int? / String? : c'est ok pour nos providers
    final todayMinutes = ref.watch(statsTodayProvider(key));
    final weekly = ref.watch(statsLast7DaysProvider(key));
    final hourly = ref.watch(hourlyTodayProvider(key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Statistiques', style: Theme.of(context).textTheme.titleLarge),

        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: todayMinutes.when(
                    data: (m) => Text('Aujourd’hui: $m min',
                        style: Theme.of(context).textTheme.titleMedium),
                    loading: () => const Text('Chargement…'),
                    error: (e, _) => Text('Erreur: $e'),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Répartition horaire (aujourd’hui)',
                    style: Theme.of(context).textTheme.titleMedium),
                hourly.when(
                  data: (data) => HourlyBarsChart(data: data),
                  loading: () => const SizedBox(
                      height: 180, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Erreur: $e'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Derniers 7 jours',
                    style: Theme.of(context).textTheme.titleMedium),
                weekly.when(
                  data: (data) => WeeklyBarsChart(data: data),
                  loading: () => const SizedBox(
                      height: 200, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Erreur: $e'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
