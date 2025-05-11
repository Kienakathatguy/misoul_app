import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:misoul_fixed_app/screens/imu_family_screen.dart';
import 'package:misoul_fixed_app/screens/family_therapy_chat_app.dart';

class HomeForFamilyScreen extends StatefulWidget {
  const HomeForFamilyScreen({super.key});

  @override
  State<HomeForFamilyScreen> createState() => _HomeForFamilyScreenState();
}

class _HomeForFamilyScreenState extends State<HomeForFamilyScreen> {
  final TextEditingController _codeController = TextEditingController();
  List<String> trackedUsers = [];
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadTrackedUsers();
  }

  Future<void> _loadTrackedUsers() async {
    if (currentUser == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('user_connections')
        .where('familyId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    setState(() {
      trackedUsers = snapshot.docs.map((doc) => doc['userId'] as String).toList();
    });
  }

  Future<void> _connectToUser() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || currentUser == null) return;

    final requestRef = FirebaseFirestore.instance.collection('connection_requests');

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
        const SnackBar(content: Text("Bạn cần được xác nhận kết nối trước khi xem biểu đồ.")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Trang người thân", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Xin chào 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            const Text("Kết nối với người thân của bạn", style: TextStyle(fontSize: 16)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _connectToUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Kết nối", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
            const SizedBox(height: 32),
            const Text("Đang theo dõi:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyTherapyChatApp()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Trò chuyện với AI", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: trackedUsers.isEmpty
                  ? const Center(child: Text("Chưa theo dõi ai cả."))
                  : ListView.builder(
                itemCount: trackedUsers.length,
                itemBuilder: (context, index) {
                  final user = trackedUsers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text("Mã người dùng: $user"),
                      subtitle: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('emotion_view_requests')
                            .where('requesterId', isEqualTo: currentUser!.uid)
                            .where('targetUserId', isEqualTo: user)
                            .orderBy('requestedAt', descending: true)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text("Đang tải...");
                          }

                          if (snapshot.hasError) {
                            return const Text("Đã xảy ra lỗi.");
                          }

                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Text("Chưa gửi yêu cầu xem biểu đồ");
                          }

                          final acceptedRequests = docs.where((doc) => doc.data()['status'] == 'accepted').toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...docs.take(2).map((doc) {
                                final data = doc.data();
                                final status = data['status'] ?? 'pending';
                                final timeframe = data['timeframe'] ?? 'không rõ';

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
                                    final data = acceptedRequests.first.data();
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
                            icon: const Icon(Icons.favorite, color: Colors.pink),
                            tooltip: "Gửi lời yêu thương",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IMissUScreen(targetUserId: user),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
