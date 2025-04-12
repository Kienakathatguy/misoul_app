import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mood.dart';
import '../services/user_mood_service.dart';
import '../services/user_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayMood();
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF97BCD9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 30, color: Colors.grey) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  "Xin chào, ${displayName.isNotEmpty ? displayName : "[user]"}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.emoji_emotions, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text("Hạnh phúc", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _editProfileDialog,
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _todayMood!.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: _todayMood!.isCustomEmoji
                ? Image.asset(_todayMood!.emojiPath!, width: 40, height: 40)
                : Text(_todayMood!.emoji, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Cảm xúc hôm nay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text(_todayMood!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🎯 Mục tiêu cá nhân", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    goal.isNotEmpty ? "✨ $goal" : "Bạn chưa đặt mục tiêu cá nhân",
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),
                  const Text("✨ Tính năng chính", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: PageView(
                      controller: PageController(viewportFraction: 0.85),
                      children: [
                        if (_todayMood != null) _buildMoodCard(),
                        _buildFeatureCard(
                          title: "Trò chuyện cùng MiBot",
                          icon: Icons.chat,
                          color: Colors.purple[100]!,
                          onTap: () => _navigateTo(context, '/chatbot'),
                        ),
                        _buildFeatureCard(
                          title: "Ghi âm cảm xúc",
                          icon: Icons.mic,
                          color: Colors.green[100]!,
                          onTap: () => _navigateTo(context, '/voice_recorder'),
                        ),
                        _buildFeatureCard(
                          title: "Nhạc chữa lành",
                          icon: Icons.music_note,
                          color: Colors.blue[100]!,
                          onTap: () => _navigateTo(context, '/healing'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            IconButton(icon: const Icon(Icons.favorite_border, color: Colors.grey), onPressed: () => _navigateTo(context, '/imu')),
            IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey), onPressed: () => _navigateTo(context, '/chatbot')),
            IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey), onPressed: () => _navigateTo(context, '/mood_tracker')),
            IconButton(icon: const Icon(Icons.music_note, color: Colors.grey), onPressed: () => _navigateTo(context, '/healing')),
            IconButton(icon: const Icon(Icons.mic, color: Colors.grey), onPressed: () => _navigateTo(context, '/scheduler')),
          ],
        ),
      ),
    );
  }
}
