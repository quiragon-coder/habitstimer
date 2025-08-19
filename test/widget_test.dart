import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:habits_timer/main.dart';

void main() {
  testWidgets('loads MyApp inside ProviderScope (bounded pump)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // On pompe quelques frames au lieu de pumpAndSettle (qui peut boucler à l'infini)
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Smoke-check : l'app monte bien au moins un MaterialApp/Scaffold
    expect(find.byType(MaterialApp), findsOneWidget);
  }, tags: ['golden']); // tag optionnel, juste pour regrouper en CI si tu veux
}
