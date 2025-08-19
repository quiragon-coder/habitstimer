import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HourlyBars extends StatelessWidget {
  final List<int> data;
  const HourlyBars({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 30)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 7)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3,
              spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].toDouble())),
            )
          ],
        ),
      ),
    );
  }
}
