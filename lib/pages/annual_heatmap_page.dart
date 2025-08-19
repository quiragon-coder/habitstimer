import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AnnualHeatmapPage extends StatefulWidget {
  const AnnualHeatmapPage({super.key});

  @override
  State<AnnualHeatmapPage> createState() => _AnnualHeatmapPageState();
}

class _AnnualHeatmapPageState extends State<AnnualHeatmapPage> {
  final db = DatabaseService();
  late DateTime start;
  late DateTime end;
  Map<DateTime, int> minutes = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    start = DateTime(now.year, 1, 1);
    _load();
  }

  Future<void> _load() async {
    final map = <DateTime, int>{};
    DateTime d = start;
    while (!d.isAfter(end)) {
      final m = await db.minutesForDay(d);
      map[DateTime(d.year, d.month, d.day)] = m;
      d = d.add(const Duration(days: 1));
    }
    setState(() => minutes = map);
  }

  Color _colorFor(int m, ColorScheme cs) {
    if (m == 0) return cs.surfaceVariant;
    if (m < 15) return cs.primaryContainer.withOpacity(0.6);
    if (m < 30) return cs.primaryContainer.withOpacity(0.8);
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final days = minutes.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap annuelle')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: days.isEmpty ? const Center(child: CircularProgressIndicator()) :
        Wrap(
          spacing: 2, runSpacing: 2,
          children: days.map((d){
            final m = minutes[d] ?? 0;
            return Container(width: 10, height: 10, color: _colorFor(m, cs));
          }).toList(),
        ),
      ),
    );
  }
}
