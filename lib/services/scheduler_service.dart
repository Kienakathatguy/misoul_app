import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SchedulerService {
  static Future<Map<String, dynamic>?> fetchRecommendations(Map<String, dynamic> data) async {
    final apiUrl = dotenv.env['SCHEDULER_API_URL'];
    if (apiUrl == null) {
      print("❌ API URL is not set in .env");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Lỗi API: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception khi gọi API: $e");
    }
    return null;
  }
}
