import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/activities_list_page.dart';
import 'pages/activity_detail_page.dart';
import 'pages/annual_heatmap_page.dart';
import 'pages/settings_page.dart';
import 'models/activity.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habits Timer',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      routes: {
        '/': (_) => const ActivitiesListPage(),
        '/heatmap': (_) => const AnnualHeatmapPage(),
        '/settings': (_) => const SettingsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/activity') {
          final a = settings.arguments as Activity;
          return MaterialPageRoute(builder: (_) => ActivityDetailPage(activity: a));
        }
        return null;
      },
    );
  }
}
