import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: ListView(
        children: const [
          ListTile(
            title: Text("Export JSON"),
            subtitle: Text("Désactivé pour l’instant"),
          ),
          ListTile(
            title: Text("Import JSON"),
            subtitle: Text("Désactivé pour l’instant"),
          ),
          ListTile(
            title: Text("Réinitialiser la base"),
            subtitle: Text("Désactivé pour l’instant"),
          ),
        ],
      ),
    );
  }
}
