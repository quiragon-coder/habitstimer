import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('button looks correct', (tester) async {
    final builder = GoldenBuilder.column()
      ..addScenario('start button', FilledButton(onPressed: (){}, child: const Text('Start')));
    await tester.pumpWidgetBuilder(builder.build());
    await screenMatchesGolden(tester, 'filled_button_start');
  }, tags: ['golden']);
}
