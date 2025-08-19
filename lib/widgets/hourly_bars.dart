import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HourlyBars extends StatelessWidget {
  final List<int> data; // 24 buckets
  const HourlyBars({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta){
              final i = v.toInt();
              if (i % 3 != 0) return const SizedBox.shrink();
              return Text("$i");
            }, interval: 1)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            for (int i=0; i<24; i++)
              BarChartGroupData(
                x: i,
                barRods: [BarChartRodData(toY: (i < data.length ? data[i] : 0).toDouble())],
              )
          ],
        ),
      ),
    );
  }
}
