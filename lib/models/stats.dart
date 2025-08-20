import 'package:flutter/foundation.dart';

@immutable
class DailyStat {
  final DateTime day; // jour tronqué à minuit local
  final int minutes;  // minutes totales sur ce jour
  const DailyStat({required this.day, required this.minutes});
}

@immutable
class HourlyBucket {
  final int hour;     // 0..23
  final int minutes;  // minutes effectuées dans cette heure
  const HourlyBucket({required this.hour, required this.minutes});
}
