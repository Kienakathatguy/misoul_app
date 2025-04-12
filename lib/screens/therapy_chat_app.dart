import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'chatbot_screen.dart';
import 'time_up_screen.dart';
import '../utils/time_manager.dart';

class TherapyChatApp extends StatefulWidget {
  const TherapyChatApp({Key? key}) : super(key: key);

  @override
  _TherapyChatAppState createState() => _TherapyChatAppState();
}

class _TherapyChatAppState extends State<TherapyChatApp> {
  List<Conversation> _conversations = [];
  int _conversationCount = 0;
  int _secondsLeft = 0;
  static const int maxSeconds = TimeManager.maxMinutes * 60;

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() async {
    final remainingMinutes = await TimeManager.getRemaining();
    setState(() {
      _secondsLeft = remainingMinutes * 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        _navigateToTimeUp();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  void _navigateToTimeUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TimeUpScreen()),
    );
  }

  String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress => _secondsLeft / maxSeconds;

  Future<void> _loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString('conversations') ?? '[]';
    final conversationsCount = prefs.getInt('conversationCount') ?? 0;

    setState(() {
      _conversationCount = conversationsCount;
      final List<dynamic> conversationsList = jsonDecode(conversationsJson);
      _conversations = conversationsList.map((json) => Conversation.fromJson(json)).toList();
    });
  }

  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = jsonEncode(_conversations.map((conv) => conv.toJson()).toList());

    await prefs.setString('conversations', conversationsJson);
    await prefs.setInt('conversationCount', _conversationCount);
  }

  void _createNewConversation() async {
    if (_secondsLeft <= 0) {
      _navigateToTimeUp();
      return;
    }

    setState(() {
      _conversationCount++;
      _conversations.add(
        Conversation(
          id: _conversationCount,
          title: "Cuộc trò chuyện $_conversationCount",
          messageCount: 0,
          mood: "Mới",
          moodColor: Colors.blue,
          timestamp: DateTime.now(),
          messages: [],
        ),
      );
    });

    await _saveConversations();
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  void _openConversation(BuildContext context, Conversation conversation) {
    if (_secondsLeft <= 0) {
      _navigateToTimeUp();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotScreen(
          conversationId: conversation.id,
          onConversationUpdated: (updatedMessages) {
            setState(() {
              final index = _conversations.indexWhere((c) => c.id == conversation.id);
              if (index != -1) {
                _conversations[index] = Conversation(
                  id: conversation.id,
                  title: conversation.title,
                  messageCount: updatedMessages.length,
                  mood: conversation.mood,
                  moodColor: conversation.moodColor,
                  timestamp: updatedMessages.isNotEmpty ? DateTime.now() : conversation.timestamp,
                  messages: updatedMessages,
                );
              }
            });
            _saveConversations();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Top section
              Container(
                color: const Color(0xFF1A0B2E),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Cuộc trò chuyện của bạn',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.home, color: Colors.white),
                              onPressed: () => _navigateTo(context, '/home'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        '$_conversationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Cuộc trò chuyện',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            color: _secondsLeft < 60 ? Colors.redAccent : Colors.greenAccent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Còn ${formatTime(_secondsLeft)} phút cho hôm nay',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // List conversation như cũ
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  child: _conversations.isEmpty
                      ? Center(
                    child: Text(
                      "Chưa có cuộc trò chuyện nào",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _openConversation(context, conversation),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF3B7F),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.chat_bubble_outline, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(conversation.title,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.message_outlined, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text('${conversation.messageCount}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: conversation.moodColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: conversation.moodColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  conversation.mood,
                                                  style: TextStyle(
                                                      fontSize: 12, color: conversation.moodColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.more_horiz),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          // Add button
          Positioned(
            top: MediaQuery.of(context).padding.top + 355,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _createNewConversation,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Conversation {
  final int id;
  final String title;
  final int messageCount;
  final String mood;
  final Color moodColor;
  final DateTime timestamp;
  final List<Map<String, dynamic>> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.messageCount,
    required this.mood,
    required this.moodColor,
    required this.timestamp,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      messageCount: json['messageCount'],
      mood: json['mood'],
      moodColor: Color(json['moodColor']),
      timestamp: DateTime.parse(json['timestamp']),
      messages: List<Map<String, dynamic>>.from(json['messages']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messageCount': messageCount,
      'mood': mood,
      'moodColor': moodColor.value,
      'timestamp': timestamp.toIso8601String(),
      'messages': messages,
    };
  }
}
