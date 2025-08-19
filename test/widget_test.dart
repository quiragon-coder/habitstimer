import 'package:flutter_test/flutter_test.dart';
import 'package:habits_timer/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('loads MyApp', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
