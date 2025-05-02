import 'package:flutter/material.dart';
import 'package:misoul_fixed_app/services/scheduler_service.dart';
import 'package:misoul_fixed_app/screens/exercise_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({Key? key}) : super(key: key);

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final DateTime selectedDate = DateTime.now();

  Map<String, dynamic> inputData = {
    "heart_rate": 75,
    "hrv": 45,
    "body_temp": 36.8,
    "sleep_quality": 65,
    "activity_level": 50,
    "mood_score": 50,
    "age": 30,
    "weight": 70,
    "mental_level": "Mild",
    "time_of_day": "Morning",
    "location": "Indoor",
    "available_minutes": 30
  };

  Map<String, dynamic>? aiResponse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch luyện tập hôm nay"),
        backgroundColor: Color(0xFFA87EF0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildDateHeader(),
            const SizedBox(height: 16),
            _buildAllStats(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: Icon(Icons.sync),
              label: Text("Tạo lịch luyện tập với AI"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white, // ✅ màu trắng cho chữ
              ),
            ),
            const SizedBox(height: 20),
            if (aiResponse != null) _buildRecommendationList(),
          ],
        ),
      ),

      // 🎯 Feature Bar
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.emoji_emotions, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/mood_tracker'),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/chatbot'),
            ),
            SizedBox(width: 50), // Space for FAB
            IconButton(
              icon: Icon(Icons.music_note, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/healing'),
            ),
            IconButton(
              icon: Icon(Icons.favorite_border, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/imu'),
            ),
          ],
        ),
      ),

      // 🎯 Floating Action Button
      floatingActionButton: Container(
        height: 60,
        width: 60,
        margin: EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          backgroundColor: Color(0xFF1A1A2E),
          child: Icon(Icons.mic, color: Colors.white),
          onPressed: () {},
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDateHeader() {
    final formatted = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today, color: Colors.purple),
        const SizedBox(width: 8),
        Text(
          "Lịch cho ngày $formatted",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAllStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("📊 Chỉ số hôm nay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var entry in inputData.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text("${_prettyKey(entry.key)}", style: const TextStyle(fontSize: 15))),
                Text("${entry.value}", style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }

  String _prettyKey(String key) {
    return key.replaceAll("_", " ").replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());
  }

  Future<void> _fetchRecommendations() async {
    final response = await SchedulerService.fetchRecommendations(inputData);
    if (response != null) {
      setState(() {
        aiResponse = response;
      });

      // LƯU KẾT QUẢ VÀO SHARED PREFERENCES
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('today_exercises', jsonEncode(response));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi khi gọi API")),
      );
    }
  }


  Widget _buildRecommendationList() {
    final recommendations = aiResponse?["recommendations"] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📝 Danh sách bài tập hôm nay",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(recommendations.length, (index) {
          final item = recommendations[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item["exercise_name"] ?? "Không có tiêu đề",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseScreen(
                                exerciseName: item["exercise_name"] ?? "Không xác định",
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Bắt đầu"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (item["description"] != null)
                    Text(
                      item["description"],
                      style: const TextStyle(color: Colors.black87),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (item["type"] != null) _buildTag("Loại: ${item["type"]}"),
                      if (item["intensity"] != null) _buildTag("Cường độ: ${item["intensity"]}"),
                      if (item["duration"] != null) _buildTag("Thời lượng: ${item["duration"]} phút"),
                      if (item["environment"] != null) _buildTag("Môi trường: ${item["environment"]}"),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }
}
