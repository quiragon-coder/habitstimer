import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/database_service.dart';

class CreateActivityPage extends StatefulWidget {
  @override
  _CreateActivityPageState createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _db = DatabaseService();

  String _emoji = "🎯";
  Color _color = Colors.blue;
  double _goalDay = 60;
  double _goalWeek = 300;
  double _goalMonth = 1200;
  double _goalYear = 14400;

  void _saveActivity() async {
    if (_formKey.currentState!.validate()) {
      final activity = Activity(
        name: _nameController.text,
        emoji: _emoji,
        color: _color.value,
        goalMinutesPerDay: _goalDay.toInt(),
        goalMinutesPerWeek: _goalWeek.toInt(),
        goalMinutesPerMonth: _goalMonth.toInt(),
        goalMinutesPerYear: _goalYear.toInt(),
      );
      await _db.addActivity(activity);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nouvelle activité")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Nom de l'activité"),
                validator: (value) =>
                value == null || value.isEmpty ? "Entrez un nom" : null,
              ),
              SizedBox(height: 20),
              Text("Emoji"),
              Row(
                children: ["🎯", "📚", "🏃", "🎨", "🎵"].map((e) {
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        e,
                        style: TextStyle(fontSize: 30,
                            backgroundColor: _emoji == e
                                ? Colors.grey[300]
                                : Colors.transparent),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text("Couleur"),
              Wrap(
                spacing: 8,
                children: [Colors.blue, Colors.red, Colors.green, Colors.orange]
                    .map((c) => GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    backgroundColor: c,
                    radius: 20,
                    child: _color == c ? Icon(Icons.check) : null,
                  ),
                ))
                    .toList(),
              ),
              SizedBox(height: 20),
              Text("Objectifs (minutes)"),
              _buildSlider("Par jour", _goalDay, (v) => setState(() => _goalDay = v)),
              _buildSlider("Par semaine", _goalWeek, (v) => setState(() => _goalWeek = v)),
              _buildSlider("Par mois", _goalMonth, (v) => setState(() => _goalMonth = v)),
              _buildSlider("Par an", _goalYear, (v) => setState(() => _goalYear = v)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveActivity,
                child: Text("Sauvegarder"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label : ${value.toInt()} min"),
        Slider(
          value: value,
          min: 0,
          max: 2000,
          divisions: 100,
          label: value.toInt().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
