import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DailyBars extends StatelessWidget {
  final List<int> hourlyMinutes;
  const DailyBars({super.key, required this.hourlyMinutes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 18, getTitlesWidget: (v, meta){
              final h = v.toInt();
              if (h % 3 != 0) return const SizedBox.shrink();
              return Text('$h');
            })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 30)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(24, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: hourlyMinutes[i].toDouble())])),
        ),
      ),
    );
  }
}
