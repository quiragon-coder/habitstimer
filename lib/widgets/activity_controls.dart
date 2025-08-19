import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/database_service.dart';

class ActivityControls extends ConsumerStatefulWidget {
  final int activityId;
  const ActivityControls({super.key, required this.activityId});

  @override
  ConsumerState<ActivityControls> createState() => _ActivityControlsState();
}

class _ActivityControlsState extends ConsumerState<ActivityControls> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final db = ref.read(dbProvider);
    final s = await db.getRunningSession(widget.activityId);
    if (s != null) {
      setState(() {
        _running = true;
        _elapsed = DateTime.now().difference(s.startAt);
      });
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(h)}:${two(m)}:${two(s)}";
    }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fmt(_elapsed), style: const TextStyle(fontFeatures: [])),
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () async {
            await db.startSession(widget.activityId);
            setState(() {
              _running = true;
              _elapsed = const Duration(seconds: 0);
            });
            _startTicker();
          },
        ),
        IconButton(
          icon: const Icon(Icons.pause),
          onPressed: _running ? () async {
            await db.togglePauseByActivity(widget.activityId);
            // keep ticker for simple UX; advanced: stop while paused
          } : null,
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          onPressed: _running ? () async {
            await db.stopSessionByActivity(widget.activityId);
            _ticker?.cancel();
            setState(() {
              _running = false;
            });
          } : null,
        ),
      ],
    );
  }
}
