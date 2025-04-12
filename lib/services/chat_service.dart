import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static final String apiUrl = "http://192.168.2.11:5000/api/chat"; // Đổi IP nếu cần

  static Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${dotenv.env['MISOUL_API_KEY']}",
        },
        body: jsonEncode({
          "message": message,
          "user_id": "user_123",
        }),
      );

      print("📡 Gửi tin nhắn: $message");
      print("📩 Phản hồi từ server: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Lỗi từ server: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi khi gửi tin nhắn: $e");
      return {"error": "Không thể gửi tin nhắn"};
    }
  }
}
