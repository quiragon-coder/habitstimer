import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/activities_list_page.dart';
import 'pages/annual_heatmap_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habits Timer',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const ActivitiesListPage(),
      routes: {
        '/settings': (_) => const SettingsPage(),
        '/heatmap': (_) => const AnnualHeatmapPage(),
      },
    );
  }
}
