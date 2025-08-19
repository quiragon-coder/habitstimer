import 'package:flutter/material.dart';

class AnnualHeatmapPage extends StatelessWidget {
  const AnnualHeatmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap annuelle')),
      body: const Center(child: Text('Heatmap à venir')),
    );
  }
}
