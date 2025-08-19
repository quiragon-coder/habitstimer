import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Un simple tick chaque seconde pour rafraîchir l'écran
final tickerProvider = StreamProvider<int>((ref) async* {
  int i = 0;
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield i++;
  }
});
