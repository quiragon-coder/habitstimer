import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import '../widgets/hourly_bars.dart';

class ActivityDetailPage extends StatefulWidget {
  final Activity activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(a.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aujourd\'hui (${DateFormat.yMMMd().format(today)})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<int>>(
              future: db.hourlyActiveMinutes(today, activityId: a.id!),
              builder: (_, snap) => snap.hasData
                  ? HourlyBars(data: snap.data!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
