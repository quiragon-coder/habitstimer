import 'package:flutter/material.dart';
import '../models/session.dart';

class DayDetailPage extends StatelessWidget {
  final DateTime day;
  const DayDetailPage({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    // Pour l’instant, sessions vides
    final sessions = <Session>[];

    return Scaffold(
      appBar: AppBar(title: Text("Détails du ${day.toLocal()}")),
      body: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, i) {
          final s = sessions[i];
          return ListTile(
            title: Text("Session ${s.id}"),
          );
        },
      ),
    );
  }
}
