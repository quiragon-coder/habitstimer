import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/database_service.dart';

class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _emoji = "⏱️";
  Color _color = const Color(0xFF2196F3);

  int? _goalDay;
  int? _goalWeek;
  int? _goalMonth;
  int? _goalYear;

  final _db = DatabaseService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final act = Activity(
      name: _nameCtrl.text.trim(),
      emoji: _emoji,
      color: _color.value,
      goalMinutesPerDay: _goalDay,
      goalMinutesPerWeek: _goalWeek,
      goalMinutesPerMonth: _goalMonth,
      goalMinutesPerYear: _goalYear,
    );

    await _db.addActivity(act);              // <-- crée en base
    if (!mounted) return;
    Navigator.pop(context, true);            // <-- renvoie "true" pour déclencher le refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle activité")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Nom"),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? "Saisis un nom" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Emoji"),
                const SizedBox(width: 12),
                Text(_emoji, style: const TextStyle(fontSize: 24)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: () async {
                    // petit choix rapide d’emojis (simple et sans dépendance)
                    final choices = ["⏱️", "📚", "💪", "✍️", "🎨", "🎹"];
                    final picked = await showDialog<String>(
                      context: context,
                      builder: (c) => SimpleDialog(
                        title: const Text("Choisir un emoji"),
                        children: choices
                            .map((e) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(c, e),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ))
                            .toList(),
                      ),
                    );
                    if (picked != null) setState(() => _emoji = picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Couleur"),
                const SizedBox(width: 12),
                Container(width: 24, height: 24, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.color_lens),
                  onPressed: () async {
                    // choix simple de couleurs (pour éviter la dépendance colorpicker)
                    final choices = <Color>[
                      const Color(0xFF2196F3),
                      const Color(0xFFE91E63),
                      const Color(0xFF4CAF50),
                      const Color(0xFFFF9800),
                      const Color(0xFF9C27B0),
                    ];
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (c) => SimpleDialog(
                        title: const Text("Choisir une couleur"),
                        children: choices
                            .map((col) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(c, col),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Text('#${col.value.toRadixString(16).padLeft(8, '0').toUpperCase()}'),
                            ],
                          ),
                        ))
                            .toList(),
                      ),
                    );
                    if (picked != null) setState(() => _color = picked);
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            // Objectifs (saisies rapides en minutes)
            TextFormField(
              decoration: const InputDecoration(labelText: "Objectif min/jour (optionnel)"),
              keyboardType: TextInputType.number,
              onChanged: (v) => _goalDay = v.isEmpty ? null : int.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Objectif min/semaine (optionnel)"),
              keyboardType: TextInputType.number,
              onChanged: (v) => _goalWeek = v.isEmpty ? null : int.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Objectif min/mois (optionnel)"),
              keyboardType: TextInputType.number,
              onChanged: (v) => _goalMonth = v.isEmpty ? null : int.tryParse(v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Objectif min/année (optionnel)"),
              keyboardType: TextInputType.number,
              onChanged: (v) => _goalYear = v.isEmpty ? null : int.tryParse(v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
