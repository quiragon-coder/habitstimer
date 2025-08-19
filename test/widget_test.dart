import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits_timer/main.dart';

void main() {
  testWidgets('loads MyApp inside ProviderScope', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Habits Timer'), findsOneWidget);
  });
}
