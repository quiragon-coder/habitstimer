import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/database_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final importCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<String>(
            future: db.databasePath(),
            builder: (_, s) => ListTile(
              title: const Text('Chemin base de données'),
              subtitle: Text(s.data ?? '...'),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Export JSON'),
            subtitle: const Text('Copie les données au format JSON'),
            trailing: FilledButton(
              onPressed: () async {
                final map = await db.exportJson();
                final json = const JsonEncoder.withIndent('  ').convert(map);
                if (!mounted) return;
                await showDialog(context: context, builder: (_)=> AlertDialog(
                  title: const Text('Export'),
                  content: SingleChildScrollView(child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace'))),
                  actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Fermer'))],
                ));
              },
              child: const Text('Exporter'),
            ),
          ),
          const Divider(),
          const Text('Import JSON'),
          TextField(
            controller: importCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '{ "activities": [...], "sessions": [...], "pauses": [...] }',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final map = jsonDecode(importCtrl.text) as Map<String,Object?>;
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
                  final map = jsonDecode(importCtrl.text) as Map<String,Object?>;
                  await db.importJson(map, reset: true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import (reset) terminé')));
                },
                icon: const Icon(Icons.restore_page),
                label: const Text('Importer (reset)'),
              ),
            ],
          ),
          const Divider(),
          OutlinedButton.icon(
            onPressed: () async {
              await db.resetDatabase();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base réinitialisée')));
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Reset base'),
          ),
        ],
      ),
    );
  }
}
