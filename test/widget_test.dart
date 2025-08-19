import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:habits_timer/main.dart';

void main() {
  testWidgets('loads MyApp inside ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Smoke-check: l'app a bien monté au moins un MaterialApp/Scaffold.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
