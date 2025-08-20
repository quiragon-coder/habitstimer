import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habitstimer/models/stats.dart';
import 'package:intl/intl.dart';

class WeeklyBarsChart extends StatelessWidget {
  final List<DailyStat> data;
  const WeeklyBarsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.E();
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      groups.add(BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: d.minutes.toDouble(), width: 14, borderRadius: BorderRadius.circular(4))],
        showingTooltipIndicators: const [0],
      ));
    }

    return SizedBox(
      height: 200,
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
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(df.format(data[i].day), style: const TextStyle(fontSize: 10)),
                );
              },
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(enabled: true),
        ),
      ),
    );
  }
}
