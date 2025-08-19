// lib/widgets/hourly_bars.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HourlyBars extends StatelessWidget {
  final List<int> data; // 24 buckets
  const HourlyBars({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = (data.isEmpty ? 0 : (data.reduce((a, b) => a > b ? a : b)));
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final h = v.toInt();
                  if (h % 3 != 0) return const SizedBox.shrink();
                  return Text('$h');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, horizontalInterval: 10),
          barGroups: List.generate(24, (i) {
            final val = i < data.length ? data[i].toDouble() : 0.0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: val),
              ],
            );
          }),
        ),
      ),
    );
  }
}
