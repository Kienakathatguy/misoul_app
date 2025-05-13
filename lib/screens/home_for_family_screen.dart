import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:misoul_fixed_app/screens/imu_family_screen.dart';
import 'package:misoul_fixed_app/screens/family_therapy_chat_app.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';


class HomeForFamilyScreen extends StatefulWidget {
  const HomeForFamilyScreen({super.key});

  @override
  State<HomeForFamilyScreen> createState() => _HomeForFamilyScreenState();
}

class _HomeForFamilyScreenState extends State<HomeForFamilyScreen> {
  final TextEditingController _codeController = TextEditingController();
  List<String> trackedUsers = [];
  final currentUser = FirebaseAuth.instance.currentUser;
  String displayName = '';
  String goal = '';
  String avatarUrl = '';


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTrackedUsers();
  }

  Future<void> _loadUserData() async {
    await UserService.createUserProfileIfNotExists();
    final data = await UserService.getUserProfile();
    if (data != null && mounted) {
      setState(() {
        displayName = data['displayName'] ?? '';
        goal = data['goal'] ?? '';
        avatarUrl = data['avatarUrl'] ?? '';
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

      if (mounted) {
        setState(() {
          avatarUrl = downloadUrl;
        });
      }
    }
  }

  void _editProfileDialog() {
    final nameController = TextEditingController(text: displayName);
    final goalController = TextEditingController(text: goal);
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Cập nhật hồ sơ"),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery
                    .of(context)
                    .size
                    .height * 0.4),
                child: Column(
                  children: [
                    TextField(controller: nameController,
                        decoration: const InputDecoration(
                            labelText: "Tên hiển thị")),
                    TextField(controller: goalController,
                        decoration: const InputDecoration(
                            labelText: "Mục tiêu cá nhân")),
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


  Future<void> _loadTrackedUsers() async {
    if (currentUser == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('user_connections')
        .where('familyId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (mounted) {
      setState(() {
        trackedUsers =
            snapshot.docs.map((doc) => doc['userId'] as String).toList();
      });
    }
  }

  Future<void> _connectToUser() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || currentUser == null) return;

    final requestRef = FirebaseFirestore.instance.collection(
        'connection_requests');

    await requestRef.add({
      'requesterId': currentUser!.uid,
      'targetId': code,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã gửi yêu cầu kết nối, chờ xác nhận")),
    );

    _codeController.clear();
    await _loadTrackedUsers();
  }

  Future<void> sendEmotionChartRequest({
    required String targetUserId,
    required String timeframe,
  }) async {
    if (currentUser == null) return;

    final connectionSnapshot = await FirebaseFirestore.instance
        .collection('user_connections')
        .where('familyId', isEqualTo: currentUser!.uid)
        .where('userId', isEqualTo: targetUserId)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (connectionSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            "Bạn cần được xác nhận kết nối trước khi xem biểu đồ.")),
      );
      return;
    }

    final existing = await FirebaseFirestore.instance
        .collection('emotion_view_requests')
        .where('requesterId', isEqualTo: currentUser!.uid)
        .where('targetUserId', isEqualTo: targetUserId)
        .where('timeframe', isEqualTo: timeframe)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) return;

    await FirebaseFirestore.instance.collection('emotion_view_requests').add({
      'requesterId': currentUser!.uid,
      'targetUserId': targetUserId,
      'timeframe': timeframe,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi yêu cầu xem biểu đồ")),
      );
      setState(() {}); // cập nhật UI sau khi gửi yêu cầu
    }
  }

  void _showChartRequestDialog(String targetUserId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['ngày', 'tuần', 'tháng', 'năm'].map((timeframe) {
              return ListTile(
                title: Text("Xem biểu đồ theo $timeframe"),
                onTap: () async {
                  Navigator.pop(context);
                  await sendEmotionChartRequest(
                    targetUserId: targetUserId,
                    timeframe: timeframe,
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Đang chờ';
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Xác nhận đăng xuất"),
            content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
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

  Widget _buildFamilyHeader() {
    final today = DateTime.now();
    final mediaQuery = MediaQuery.of(context);
    final weekday = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"][today.weekday %
        7];
    final formattedDate = "$weekday, ${today.day} tháng ${today.month} ${today
        .year}";

    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: "Đăng xuất",
              onPressed: () => _confirmLogout(context),
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
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(
                      avatarUrl) : null,
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
                      "Xin chào, ${displayName.isNotEmpty
                          ? displayName
                          : "Người thân"}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (goal.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        goal,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: _editProfileDialog,
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: ListView(
        padding: const EdgeInsets.all(0),
        // Không padding ngoài, chỉ padding bên trong
        children: [
          _buildFamilyHeader(), // ✅ header tràn full màn hình

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text("Kết nối với người thân của bạn",
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: "Nhập mã người dùng",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _connectToUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF333333),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                          "Kết nối", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),

                const SizedBox(height: 32),
                const Text("Đang theo dõi:", style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FamilyTherapyChatApp()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(
                      "Trò chuyện với AI", style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 20),

                trackedUsers.isEmpty
                    ? const Center(child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("Chưa theo dõi ai cả."),
                ))
                    : Column(
                  children: trackedUsers.map((user) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text("Mã người dùng: $user"),
                        subtitle: FutureBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance
                              .collection('emotion_view_requests')
                              .where('requesterId', isEqualTo: currentUser!.uid)
                              .where('targetUserId', isEqualTo: user)
                              .orderBy('requestedAt', descending: true)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text("Đang tải...");
                            }
                            if (snapshot.hasError) {
                              return const Text("Đã xảy ra lỗi.");
                            }

                            final docs = snapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Text("Chưa gửi yêu cầu xem biểu đồ");
                            }

                            final acceptedRequests = docs.where((doc) =>
                            doc.data()['status'] == 'accepted').toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...docs.take(2).map((doc) {
                                  final data = doc.data();
                                  final status = data['status'] ?? 'pending';
                                  final timeframe = data['timeframe'] ??
                                      'không rõ';

                                  return Text(
                                    "• $timeframe - ${_statusLabel(status)}",
                                    style: TextStyle(
                                      color: status == 'accepted'
                                          ? Colors.green
                                          : status == 'rejected'
                                          ? Colors.red
                                          : Colors.orange,
                                      fontSize: 13,
                                    ),
                                  );
                                }),
                                if (acceptedRequests.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      final data = acceptedRequests.first
                                          .data();
                                      Navigator.pushNamed(
                                        context,
                                        '/emotion_chart',
                                        arguments: {
                                          'userId': user,
                                          'timeframe': data['timeframe'],
                                        },
                                      );
                                    },
                                    child: const Text("Xem biểu đồ"),
                                  ),
                              ],
                            );
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.favorite, color: Colors.pink),
                              tooltip: "Gửi lời yêu thương",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        IMissUScreen(targetUserId: user),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.bar_chart),
                              tooltip: "Gửi yêu cầu xem biểu đồ",
                              onPressed: () => _showChartRequestDialog(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
