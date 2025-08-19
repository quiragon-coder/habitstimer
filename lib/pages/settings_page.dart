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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: db.databasePath(),
              builder: (_, s) => Text('DB: ${s.data ?? ''}'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final map = await db.exportJson();
                    final jsonStr = const JsonEncoder.withIndent("  ").convert(map);
                    if (!mounted) return;
                    await showDialog(context: context, builder: (_) => AlertDialog(
                      title: const Text('Export JSON'),
                      content: SingleChildScrollView(child: SelectableText(jsonStr)),
                      actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Fermer'))],
                    ));
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Exporter'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final map = jsonDecode(importCtrl.text) as Map<String, Object?>;
                    await db.importJson(map, reset: false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import terminé')));
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Importer'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final map = jsonDecode(importCtrl.text) as Map<String, Object?>;
                    await db.importJson(map, reset: true);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import (reset) terminé')));
                  },
                  icon: const Icon(Icons.restore_page),
                  label: const Text('Importer (reset)'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: importCtrl,
              decoration: const InputDecoration(
                labelText: 'Coller ici un JSON exporté',
                border: OutlineInputBorder(),
              ),
              minLines: 4, maxLines: 12,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await db.resetDatabase();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base réinitialisée')));
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset DB'),
            ),
          ],
        ),
      ),
    );
  }
}
