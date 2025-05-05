import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MoodChart extends StatelessWidget {
  final List<int> moodData;
  final String viewType; // "Ngày", "Tuần", "Tháng", "Năm"

  MoodChart({
    required this.moodData,
    required this.viewType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => _buildBottomTitle(value),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                moodData.length,
                    (index) => FlSpot(index.toDouble(), moodData[index].toDouble()),
              ),
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTitle(double value) {
    final index = value.toInt();
    String label = "";

    switch (viewType) {
      case "Tuần":
        const weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
        if (index >= 0 && index < weekdays.length) label = weekdays[index];
        break;
      case "Tháng":
        label = "T${index + 1}";
        break;
      case "Năm":
        const months = ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11", "T12"];
        if (index >= 0 && index < months.length) label = months[index];
        break;
      default: // Ngày
        label = "${index + 1}";
    }

    return Text(label, style: TextStyle(fontSize: 12));
  }
}
