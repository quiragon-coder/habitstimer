import 'package:flutter/material.dart';
import 'package:habits_timer/models/activity.dart';
import 'package:habits_timer/services/database_service.dart';

class ActivityControls extends StatefulWidget {
  final Activity activity;
  const ActivityControls({super.key, required this.activity});

  @override
  State<ActivityControls> createState() => _ActivityControlsState();
}

class _ActivityControlsState extends State<ActivityControls> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _db.getRunningSession(widget.activity.id!),
      builder: (_, snap) {
        final running = snap.data;
        final isRunning = running != null;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Start',
              onPressed: isRunning
                  ? null
                  : () async {
                await _db.startSession(widget.activity.id!);
                if (mounted) setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              tooltip: 'Pause / Unpause',
              onPressed: isRunning
                  ? () async {
                await _db.togglePause(running.id);
                if (mounted) setState(() {});
              }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Stop',
              onPressed: isRunning
                  ? () async {
                await _db.stopSession(running.id);
                if (mounted) setState(() {});
              }
                  : null,
            ),
          ],
        );
      },
    );
  }
}
