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
  import '../screens/connected_family_screen.dart';
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
    final ScrollController _scrollController = ScrollController();
    int _currentIndex = 0;
  
    @override
    void initState() {
      super.initState();
      _loadUserData();
      _loadTodayMood();
      _loadChatbotTime();
      _loadExercisesFromPrefs();
  
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _loadChatbotTime());
      _scrollController.addListener(() {
        final position = _scrollController.position.pixels;
        final itemWidth = 176; // 160 card width + 16 margin
        final index = (position + itemWidth / 2) ~/ itemWidth;
  
        if (index != _currentIndex) {
          setState(() => _currentIndex = index);
        }
      });
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
        if (decoded is Map<String, dynamic>) {
          final list = List<Map<String, dynamic>>.from(decoded['recommendations'] ?? []);
          setState(() {
            todayExercises = list;
          });
        }
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
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên hiển thị")),
                  TextField(controller: goalController, decoration: const InputDecoration(labelText: "Mục tiêu cá nhân")),
                ],
              ),
            ),
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
      if (Navigator.canPop(context)) {
        Navigator.pushNamed(context, route);
      } else {
        Navigator.of(context).pushNamed(route);
      }
    }
  
    Widget _buildUserHeader() {
      final today = DateTime.now();
      final mediaQuery = MediaQuery.of(context);
      final weekday = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"][today.weekday % 7];
      final formattedDate = "$weekday, ${today.day} tháng ${today.month} ${today.year}";
      final uid = FirebaseAuth.instance.currentUser?.uid;
  
      return Container(
        width: double.infinity,
        // Remove fixed height constraints and let content determine size
        padding: EdgeInsets.only(
          top: mediaQuery.padding.top + 4,
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
          mainAxisSize: MainAxisSize.min, // Make column take minimum required space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRequestButton(
                    icon: Icons.group_add,
                    tooltip: "Lời mời kết nối",
                    collection: 'connectionRequests',
                    route: '/connection_requests',
                  ),
                  const SizedBox(width: 8),
                  _buildRequestButton(
                    icon: Icons.notifications_outlined,
                    tooltip: "Yêu cầu xem biểu đồ cảm xúc",
                    collection: 'emotionViewRequests',
                    route: '/emotion_requests',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: "Đăng xuất",
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 32, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Xin chào, ${displayName.isNotEmpty ? displayName : "User"}",
                        style: const TextStyle(
                          fontSize: 22, // Reduced from 26 to 22
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2, // Reduced from 1.3 to 1.2
                        ),
                        overflow: TextOverflow.ellipsis, // Add this to prevent text overflow
                        maxLines: 1, // Limit to 1 line
                      ),
                      const SizedBox(height: 8), // Reduced from 10 to 8
                      Row(
                        children: const [
                          Icon(Icons.favorite, color: Colors.white, size: 18), // Reduced from 20 to 18
                          SizedBox(width: 4), // Reduced from 6 to 4
                          Text("80%", style: TextStyle(color: Colors.white, fontSize: 14)), // Reduced from 16 to 14
                          SizedBox(width: 8), // Reduced from 12 to 8
                          Icon(Icons.emoji_emotions_outlined, color: Colors.white, size: 18), // Reduced from 20 to 18
                          SizedBox(width: 4), // Reduced from 6 to 4
                          Text("Hạnh phúc", style: TextStyle(color: Colors.white, fontSize: 14)), // Reduced from 16 to 14
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _editProfileDialog,
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20), // Reduced from 22 to 20
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      );
    }
  
    Widget _buildRequestButton({
      required IconData icon,
      required String tooltip,
      required String collection,
      required String route,
    }) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection(collection)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          int count = snapshot.data!.docs.length;
          return Stack(
            children: [
              IconButton(
                icon: Icon(icon, color: Colors.white),
                tooltip: tooltip,
                onPressed: () => Navigator.pushNamed(context, route),
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 7,
                    backgroundColor: Colors.red,
                    child: Text(
                      count.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
  
    Widget _buildFeatureCard({
      required String title,
      String? subtitle,
      IconData? icon,
      String? emoji,
      String? emojiPath,
      Color? bgColor,
      Widget? backgroundImage,
      Widget? centerContent,
      VoidCallback? onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 160,
          height: 160,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  borderRadius: BorderRadius.circular(20),
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
        subtitle: "Còn $chatbotMinutesLeft'",
        icon: Icons.chat_bubble_outline,
        bgColor: const Color(0xFFFF8FA5),
        backgroundImage: Image.asset(
          'assets/images/chatbot_timer_circle.png',
          fit: BoxFit.cover,
        ),
        centerContent: Text(
          "$chatbotMinutesLeft'",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onTap: () => _navigateTo(context, '/chatbot'),
      );
    }

    Widget _buildMoodCard() {
      return _buildFeatureCard(
        title: "Tâm trạng",
        subtitle: _todayMood?.name ?? 'Chưa có',
        emoji: _todayMood?.emoji,
        emojiPath: _todayMood?.emojiPath,
        bgColor: Colors.purple,
        centerContent: Image.asset(
          'assets/images/mood_chart.png',
          fit: BoxFit.contain,
          height: 60,
        ),
      );
    }

    Widget _buildConnectCard() {
      return _buildFeatureCard(
        title: "Người thân đã kết nối ",
        icon: Icons.favorite, // hoặc Icons.group, tuỳ style bạn chọn
        bgColor: Colors.orangeAccent,
        onTap: () => Navigator.pushNamed(context, '/connected_family'),
      );
    }


    Widget _buildExerciseCard() {
      if (todayExercises.isEmpty) return const SizedBox.shrink();
  
      final firstExercise = todayExercises[0];
      final name = firstExercise['exercise_name'] ?? "Bài tập";
  
      return _buildFeatureCard(
        title: name,
        subtitle: "Hôm nay",
        icon: Icons.fitness_center,
        bgColor: Colors.deepPurpleAccent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseScreen(exerciseName: name),
            ),
          );
        },
      );
    }
  
  
    void _confirmLogout(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Xác nhận đăng xuất"),
          content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Đóng dialog
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text("Đăng xuất"),
            ),
          ],
        ),
      );
    }
  
  
    @override
    Widget build(BuildContext context) {
      final mediaQuery = MediaQuery.of(context);
  
      final featureCards = [
        _buildChatbotCard(),
        _buildExerciseCard(),
        _buildMoodCard(),
        _buildConnectCard(),
      ];
  
      return Scaffold(
        backgroundColor: const Color(0xFFF6F1FF),
        body: ListView(
          children: [
            _buildUserHeader(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("✨ Tính năng chính", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 180,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: featureCards.length,
                itemBuilder: (context, index) => featureCards[index],
              ),
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(featureCards.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? Colors.black : Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
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