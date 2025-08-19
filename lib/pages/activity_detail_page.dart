import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityDetailPage extends StatelessWidget {
  final Activity activity;

  const ActivityDetailPage({Key? key, required this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color(activity.color);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(activity.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                activity.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero card (couleur + emoji + nom)
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  activity.emoji,
                  style: const TextStyle(fontSize: 42),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Objectifs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _Goals(activity: activity),
            ),
          ),
          const SizedBox(height: 16),

          // Graphique placeholder (à brancher plus tard)
          Card(
            child: SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  "Graphiques à venir (jour / semaine / mois / année)",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Historique placeholder (à brancher plus tard)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Historique des sessions (début → fin, durée)\n"
                    "— À connecter quand les méthodes SQLite seront finalisées —",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Goals extends StatelessWidget {
  const _Goals({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    void addRow(String label, int? minutes) {
      if (minutes == null) return;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.flag, size: 18),
              const SizedBox(width: 8),
              Text(
                "$label : ",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text("$minutes min"),
            ],
          ),
        ),
      );
    }

    addRow("Objectif / jour", activity.goalMinutesPerDay);
    addRow("Objectif / semaine", activity.goalMinutesPerWeek);
    addRow("Objectif / mois", activity.goalMinutesPerMonth);
    addRow("Objectif / an", activity.goalMinutesPerYear);

    if (rows.isEmpty) {
      return const Text("Aucun objectif défini");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Objectifs",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}
