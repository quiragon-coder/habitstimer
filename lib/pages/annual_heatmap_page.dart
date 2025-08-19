import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/database_service.dart';

class AnnualHeatmapPage extends ConsumerWidget {
  const AnnualHeatmapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year + 1, 1, 1);
    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap annuelle')),
      body: FutureBuilder<Map<DateTime,int>>(
        future: db.dailyActiveMinutes(start, end),
        builder: (_, snap){
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!;
          final days = List<DateTime>.generate(end.difference(start).inDays, (i)=> start.add(Duration(days: i)));
          final maxVal = (data.values.isEmpty ? 0 : data.values.reduce((a,b)=> a>b?a:b)).clamp(0, 60);
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              children: [
                for (final d in days)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colorFor(data[d] ?? 0, maxVal, Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Color _colorFor(int minutes, int max, Color base) {
    if (max <= 0) return base.withOpacity(0.08);
    final t = (minutes / max).clamp(0, 1).toDouble();
    return base.withOpacity(0.1 + 0.9 * t);
  }
}
