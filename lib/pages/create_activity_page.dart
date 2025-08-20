import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/activity.dart';
import '../services/database_service.dart';

class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _nameCtrl = TextEditingController();
  final _db = DatabaseService();

  String _emoji = '⏱️';
  Color _color = const Color(0xFF2196F3);

  // Minutes par défaut (exemples raisonnables)
  double _goalDay = 60;       // 1 h
  double _goalWeek = 300;     // 5 h
  double _goalMonth = 1200;   // 20 h
  double _goalYear = 14400;   // 240 h

  // Bornes en minutes
  static const double _dayMax = 24 * 60.0;       // 1440
  static const double _weekMax = 7 * 24 * 60.0;  // 10080
  static const double _monthMax = 31 * 24 * 60.0; // 44640
  static const double _yearMax = 366 * 24 * 60.0; // 527040

  // Pour éviter toute assertion si une valeur dépasse la borne
  double _clamp(double v, double max) => v.clamp(0, max).toDouble();

  String _minsToLabel(double mins) {
    final m = mins.round();
    final h = m ~/ 60;
    final r = m % 60;
    if (h == 0) return '$m min';
    if (r == 0) return '${h}h';
    return '${h}h${r.toString().padLeft(2, '0')}';
  }

  Future<void> _pickColor() async {
    Color temp = _color;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            portraitOnly: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    ).then((ok) {
      if (ok == true) setState(() => _color = temp);
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donne un nom à l’activité 🙂')));
      return;
    }
    final activity = Activity(
      name: name,
      emoji: _emoji,
      color: _color.value,
      goalMinutesPerDay: _clamp(_goalDay, _dayMax).round(),
      goalMinutesPerWeek: _clamp(_goalWeek, _weekMax).round(),
      goalMinutesPerMonth: _clamp(_goalMonth, _monthMax).round(),
      goalMinutesPerYear: _clamp(_goalYear, _yearMax).round(),
    );
    await _db.addActivity(activity);
    if (!mounted) return;
    Navigator.pop(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle activité')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nom
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom',
              hintText: 'Ex: Dessin, Sport, Lecture...',
            ),
          ),
          const SizedBox(height: 16),

          // Emoji + Couleur
          Row(
            children: [
              Text('Emoji: ', style: Theme.of(context).textTheme.titleMedium),
              Text(_emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: ['⏱️','🎨','🏃‍♂️','📚','💻','🎹','🧘','🎮'].map((e) {
                  final selected = e == _emoji;
                  return ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 18)),
                    selected: selected,
                    onSelected: (_) => setState(() => _emoji = e),
                  );
                }).toList(),
              ),
              const Spacer(),
              InkWell(
                onTap: _pickColor,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Objectif / Jour
          Text('Objectif par JOUR: ${_minsToLabel(_clamp(_goalDay, _dayMax))}'),
          Slider(
            min: 0,
            max: _dayMax,
            divisions: _dayMax.toInt(),
            value: _clamp(_goalDay, _dayMax),
            label: _minsToLabel(_clamp(_goalDay, _dayMax)),
            onChanged: (v) => setState(() => _goalDay = v),
          ),
          const SizedBox(height: 8),

          // Objectif / Semaine
          Text('Objectif par SEMAINE: ${_minsToLabel(_clamp(_goalWeek, _weekMax))}'),
          Slider(
            min: 0,
            max: _weekMax,
            divisions: (_weekMax / 5).round(),
            value: _clamp(_goalWeek, _weekMax),
            label: _minsToLabel(_clamp(_goalWeek, _weekMax)),
            onChanged: (v) => setState(() => _goalWeek = v),
          ),
          const SizedBox(height: 8),

          // Objectif / Mois
          Text('Objectif par MOIS: ${_minsToLabel(_clamp(_goalMonth, _monthMax))}'),
          Slider(
            min: 0,
            max: _monthMax,
            divisions: (_monthMax / 10).round(),
            value: _clamp(_goalMonth, _monthMax),
            label: _minsToLabel(_clamp(_goalMonth, _monthMax)),
            onChanged: (v) => setState(() => _goalMonth = v),
          ),
          const SizedBox(height: 8),

          // Objectif / Année
          Text('Objectif par ANNÉE: ${_minsToLabel(_clamp(_goalYear, _yearMax))}'),
          Slider(
            min: 0,
            max: _yearMax,
            divisions: (_yearMax / 60).round(), // pas trop de divisions pour rester fluide
            value: _clamp(_goalYear, _yearMax),
            label: _minsToLabel(_clamp(_goalYear, _yearMax)),
            onChanged: (v) => setState(() => _goalYear = v),
          ),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Créer l’activité'),
          ),
        ],
      ),
    );
  }
}
