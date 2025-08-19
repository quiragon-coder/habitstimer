import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('button looks correct', (tester) async {
    final widget = MaterialApp(
      home: Scaffold(
        body: Center(
          child: FilledButton(onPressed: () {}, child: const Text('Start')),
        ),
      ),
    );

    await tester.pumpWidgetBuilder(widget);
    await screenMatchesGolden(tester, 'filled_button_start');
  });
}
