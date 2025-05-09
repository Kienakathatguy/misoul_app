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

    final now = DateTime.now();

    switch (viewType) {
      case "Ngày":
      // Chỉ 1 điểm dữ liệu → hiển thị hôm nay
        label = "${now.day}/${now.month}";
        break;

      case "Tuần":
        const weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
        if (index >= 0 && index < weekdays.length) {
          label = weekdays[index];
        }
        break;

      case "Tháng":
        label = "${index + 1}";
        break;

      case "Năm":
        const months = ["Th1", "Th2", "Th3", "Th4", "Th5", "Th6", "Th7", "Th8", "Th9", "Th10", "Th11", "Th12"];
        if (index >= 0 && index < months.length) {
          label = months[index];
        }
        break;

      default:
        label = "${index + 1}";
    }

    return Text(label, style: const TextStyle(fontSize: 12));
  }

}
