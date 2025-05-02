import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood.dart';
import '../services/user_mood_service.dart';
import '../services/user_service.dart';
import '../utils/time_manager.dart';
import 'exercise_screen.dart';

Mood? _todayMood;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String displayName = '';
  String goal = '';
  String avatarUrl = '';
  int chatbotMinutesLeft = 0;
  Timer? _timer;
  List<Map<String, dynamic>> todayExercises = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayMood();
    _loadChatbotTime();
    _loadExercisesFromPrefs();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _loadChatbotTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    await UserService.createUserProfileIfNotExists();
    final data = await UserService.getUserProfile();
    if (data != null) {
      setState(() {
        displayName = data['displayName'] ?? '';
        goal = data['goal'] ?? '';
        avatarUrl = data['avatarUrl'] ?? '';
      });
    }
  }

  Future<void> _loadTodayMood() async {
    final moodIndex = await UserMoodService.getTodayMoodIndex();
    if (moodIndex != null) {
      setState(() {
        _todayMood = Mood.allMoods.firstWhere(
              (m) => m.index == moodIndex,
          orElse: () => Mood.neutral,
        );
      });
    }
  }

  Future<void> _loadChatbotTime() async {
    final remaining = await TimeManager.getRemaining();
    setState(() {
      chatbotMinutesLeft = remaining;
    });
  }

  Future<void> _loadExercisesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('today_exercises');
    if (data != null) {
      final decoded = jsonDecode(data);
      final list = List<Map<String, dynamic>>.from(decoded['recommendations'] ?? []);
      setState(() {
        todayExercises = list;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final ref = FirebaseStorage.instance.ref().child("avatars/$uid.jpg");
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'avatarUrl': downloadUrl,
      });

      setState(() {
        avatarUrl = downloadUrl;
      });
    }
  }

  void _editProfileDialog() {
    final nameController = TextEditingController(text: displayName);
    final goalController = TextEditingController(text: goal);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật hồ sơ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên hiển thị")),
            TextField(controller: goalController, decoration: const InputDecoration(labelText: "Mục tiêu cá nhân")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await UserService.updateUserProfile(
                displayName: nameController.text,
                goal: goalController.text,
              );
              Navigator.pop(context);
              _loadUserData();
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  Widget _buildUserHeader() {
    final today = DateTime.now();
    final weekday = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"][today.weekday % 7];
    final formattedDate = "$weekday, ${today.day} tháng ${today.month} ${today.year}";

    return Container(
      height: MediaQuery.of(context).size.height * 0.30,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFF4D79),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 36, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Xin chào, ${displayName.isNotEmpty ? displayName : "User"}",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(Icons.favorite, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text("80%", style: TextStyle(color: Colors.white, fontSize: 16)),
                        SizedBox(width: 12),
                        Icon(Icons.emoji_emotions_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text("Hạnh phúc", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _editProfileDialog,
                icon: const Icon(Icons.edit, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    String? subtitle,
    IconData? icon,
    String? emoji,
    String? emojiPath,
    Color? bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.grey[200],
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, size: 28, color: Colors.white)
            else if (emojiPath != null)
              Image.asset(emojiPath, width: 36, height: 36)
            else if (emoji != null)
                Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🏋️ Bài tập hôm nay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (todayExercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: const Text("Bạn chưa có bài tập nào hôm nay.", style: TextStyle(fontSize: 15)),
            )
          else
            Column(
              children: todayExercises.take(2).map((exercise) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseScreen(exerciseName: exercise['exercise_name']),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.deepPurple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            exercise['exercise_name'] ?? 'Bài tập không xác định',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildChatbotCard() {
    return _buildFeatureCard(
      title: "MiBot",
      subtitle: "Còn $chatbotMinutesLeft’",
      icon: Icons.chat_bubble_outline,
      bgColor: const Color(0xFFFF8FA5),
      onTap: () => _navigateTo(context, '/chatbot'),
    );
  }

  Widget _buildMoodCard() {
    return _buildFeatureCard(
      title: "Tâm trạng",
      subtitle: _todayMood?.name ?? 'Chưa có',
      emoji: _todayMood?.emoji,
      emojiPath: _todayMood?.emojiPath,
      bgColor: _todayMood?.color ?? Colors.purple,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            child: _buildUserHeader(),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("✨ Tính năng chính", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: [
                _buildChatbotCard(),
                _buildMoodCard(),
                _buildFeatureCard(
                  title: "Ghi âm",
                  subtitle: "Ghi lại cảm xúc",
                  icon: Icons.mic,
                  bgColor: Colors.greenAccent.shade100,
                  onTap: () => _navigateTo(context, '/voice_recorder'),
                ),
                _buildFeatureCard(
                  title: "Nhạc chữa lành",
                  subtitle: "Âm thanh thư giãn",
                  icon: Icons.music_note,
                  bgColor: Colors.blueAccent.shade100,
                  onTap: () => _navigateTo(context, '/healing'),
                ),
              ],
            ),
          ),
          _buildExerciseSection(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: const Icon(Icons.favorite_border), onPressed: () => _navigateTo(context, '/imu')),
            IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => _navigateTo(context, '/chatbot')),
            IconButton(icon: const Icon(Icons.emoji_emotions_outlined), onPressed: () => _navigateTo(context, '/mood_tracker')),
            IconButton(icon: const Icon(Icons.music_note), onPressed: () => _navigateTo(context, '/healing')),
            IconButton(icon: const Icon(Icons.schedule), onPressed: () => _navigateTo(context, '/scheduler')),
          ],
        ),
      ),
    );
  }
}
