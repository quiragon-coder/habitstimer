import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/session.dart';

class DayDetailPage extends StatefulWidget {
  final DateTime day;
  const DayDetailPage({super.key, required this.day});

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  final db = DatabaseService();
  List<Session> sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final start = DateTime(widget.day.year, widget.day.month, widget.day.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    sessions = await db.getSessionsBetween(start, end);
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('yMMMd').format(widget.day))),
      body: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (_, i){
          final s = sessions[i];
          final dur = (s.endAt ?? DateTime.now()).difference(s.startAt);
          return ListTile(
            leading: const Icon(Icons.timer),
            title: Text('${DateFormat.Hm().format(s.startAt)} → ${s.endAt==null ? '...' : DateFormat.Hm().format(s.endAt!)}'),
            subtitle: Text('${dur.inMinutes} min'),
          );
        },
      ),
    );
  }
}
