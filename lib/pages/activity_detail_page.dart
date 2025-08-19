import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../widgets/hourly_bars.dart';

class ActivityDetailPage extends StatelessWidget {
  final Activity activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    // Pour l’instant, données vides
    final data = List<int>.filled(24, 0);

    return Scaffold(
      appBar: AppBar(title: Text(activity.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: HourlyBars(data: data),
      ),
    );
  }
}
