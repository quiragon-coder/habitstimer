// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habits_timer/main.dart';          // MyApp
import 'package:habits_timer/providers.dart';     // activitiesProvider
import 'package:habits_timer/models/activity.dart';

void main() {
  testWidgets('loads MyApp inside ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );
    // Laisse 1 frame pour stabiliser l’UI (évite les timeouts)
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('shows empty state message when no activities', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // IMPORTANT : renvoyer une List<Activity> vide
          activitiesProvider.overrideWith((ref) async => <Activity>[]),
        ],
        child: const MyApp(),
      ),
    );

    // Laisse le Future du provider se résoudre
    await tester.pump(const Duration(milliseconds: 400));

    // Assertion robuste : texte exact OU texte contenant le début du message
    final exact = find.text('Ajoute une activité avec le +');
    final fuzzy = find.textContaining('Ajoute une activité');

    expect(exact.evaluate().isNotEmpty || fuzzy.evaluate().isNotEmpty, true,
        reason:
        'Le message d’état vide n’a pas été trouvé. Vérifie la chaîne affichée dans ActivitiesListPage.');
  });
}
