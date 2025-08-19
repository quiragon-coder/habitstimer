import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DailyBars extends StatelessWidget {
  final Map<DateTime, int> data;
  const DailyBars({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()..sort((a,b)=>a.key.compareTo(b.key));
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta){
              final i = v.toInt();
              if (i < 0 || i >= entries.length) return const SizedBox.shrink();
              final d = entries[i].key;
              return Text("${d.day}/${d.month}",
                style: const TextStyle(fontSize: 10));
            }, interval: 1)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            for (int i=0; i<entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [BarChartRodData(toY: entries[i].value.toDouble())],
              )
          ],
        ),
      ),
    );
  }
}
