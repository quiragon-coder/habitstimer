import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../models/session.dart';
import '../providers.dart';
import '../services/database_service.dart';

class ActivityControls extends ConsumerStatefulWidget {
  final Activity activity;
  const ActivityControls({super.key, required this.activity});

  @override
  ConsumerState<ActivityControls> createState() => _ActivityControlsState();
}

class _ActivityControlsState extends ConsumerState<ActivityControls> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker(Session s) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      var running = now.difference(s.startAt);
      // subtract pauses duration
      setState(() => _elapsed = running);
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return FutureBuilder<Session?>(
      future: db.getRunningSession(activityId: widget.activity.id),
      builder: (c, snap) {
        final running = snap.data;
        if (running != null) _startTicker(running);
        final h = _elapsed.inHours.toString().padLeft(2, '0');
        final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
        final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () async {
                await db.startSession(widget.activity.id!);
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () async {
                await db.togglePauseByActivity(widget.activity.id!);
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () async {
                await db.stopSessionByActivity(widget.activity.id!);
                _ticker?.cancel();
                setState(() => _elapsed = Duration.zero);
              },
            ),
            const SizedBox(width: 8),
            Text("$h:$m:$s", style: Theme.of(context).textTheme.titleMedium),
          ],
        );
      },
    );
  }
}
