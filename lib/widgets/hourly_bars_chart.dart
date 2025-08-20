import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/stats.dart';

class HourlyBarsChart extends StatelessWidget {
  final List<HourlyBucket> data;
  const HourlyBarsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final groups = data.map((b) => BarChartGroupData(
      x: b.hour,
      barRods: [BarChartRodData(toY: b.minutes.toDouble(), width: 8)],
    )).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final h = value.toInt();
                return Text(h % 6 == 0 ? '$h' : '', style: const TextStyle(fontSize: 10));
              },
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}
