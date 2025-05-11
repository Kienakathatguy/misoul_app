import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FamilyChatbotScreen extends StatefulWidget {
  final String threadId;
  const FamilyChatbotScreen({super.key, required this.threadId});

  @override
  State<FamilyChatbotScreen> createState() => _FamilyChatbotScreenState();
}

class _FamilyChatbotScreenState extends State<FamilyChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || currentUser == null) return;

    final messagesRef = FirebaseFirestore.instance.collection('familyChatMessages');

    // Gửi message người thân
    await messagesRef.add({
      'threadId': widget.threadId,
      'sender': 'family',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Gọi API chatbot
    final response = await http.post(
      Uri.parse('https://your-backend.com/api/chatbot'), // <- Đổi thành endpoint thật
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'message': text,
        'role': 'family',
        'threadId': widget.threadId,
      }),
    );

    final responseData = json.decode(response.body);

    // Gửi phản hồi AI
    await messagesRef.add({
      'threadId': widget.threadId,
      'sender': 'bot',
      'text': responseData['response'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Cập nhật thời gian cho thread
    await FirebaseFirestore.instance.collection('familyChatThreads').doc(widget.threadId).update({
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('familyChatMessages')
        .where('threadId', isEqualTo: widget.threadId)
        .orderBy('timestamp');

    return Scaffold(
      appBar: AppBar(title: const Text("Chat với AI")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg['sender'] == 'family';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['text']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Nhập tin nhắn..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
