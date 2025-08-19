import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final db = DatabaseService();
  final importCtrl = TextEditingController();
  String path = '';

  @override
  void initState() {
    super.initState();
    db.databasePath().then((p)=> setState(()=> path = p));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Chemin DB: $path'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final jsonStr = await db.exportJson();
                importCtrl.text = const JsonEncoder.withIndent('  ').convert(jsonDecode(jsonStr));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export généré ci-dessous.')));
              },
              icon: const Icon(Icons.download),
              label: const Text('Exporter → zone de texte'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: importCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'JSON à importer'),
              maxLines: 12,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final map = jsonDecode(importCtrl.text);
                    await db.importJson(map, reset: false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import terminé')));
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Importer'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final map = jsonDecode(importCtrl.text);
                    await db.importJson(map, reset: true);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import (reset) terminé')));
                  },
                  icon: const Icon(Icons.restore_page),
                  label: const Text('Importer (reset)'),
                ),
              ],
            ),
            const Divider(height: 24),
            TextButton.icon(
              onPressed: () async {
                await db.resetDatabase();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base réinitialisée')));
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset DB'),
            )
          ],
        ),
      ),
    );
  }
}
