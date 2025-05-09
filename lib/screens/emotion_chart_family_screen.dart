import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:misoul_fixed_app/widgets/mood_chart.dart'; // Đảm bảo bạn đã import widget này

class EmotionChartScreen extends StatefulWidget {
  final String userId;
  final String timeframe;

  const EmotionChartScreen({
    Key? key,
    required this.userId,
    required this.timeframe,
  }) : super(key: key);

  @override
  State<EmotionChartScreen> createState() => _EmotionChartScreenState();
}

class _EmotionChartScreenState extends State<EmotionChartScreen> {
  List<int> moodData = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('chartData')
          .doc('moodChart')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final rawList = data?[widget.timeframe];

        if (rawList != null && rawList is List) {
          setState(() {
            moodData = List<int>.from(rawList.map((e) => e ?? 3));
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "Không tìm thấy dữ liệu biểu đồ cho thời gian '${widget.timeframe}'.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Dữ liệu biểu đồ không tồn tại.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Lỗi khi tải dữ liệu: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Biểu đồ cảm xúc")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: MoodChart(
          moodData: moodData,
          viewType: widget.timeframe,
        ),
      ),
    );
  }
}
