import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeForFamilyScreen extends StatefulWidget {
  const HomeForFamilyScreen({super.key});

  @override
  State<HomeForFamilyScreen> createState() => _HomeForFamilyScreenState();
}

class _HomeForFamilyScreenState extends State<HomeForFamilyScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _connectToUser() async {
    final code = _codeController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (code.isEmpty || currentUser == null) return;

    final requestRef = FirebaseFirestore.instance.collection('connection_requests');

    await requestRef.add({
      'requesterId': currentUser.uid,
      'targetId': code,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã gửi yêu cầu kết nối, chờ xác nhận")),
    );

    _codeController.clear();
  }

  Stream<List<String>> _acceptedConnectionsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('connection_requests')
        .where('requesterId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc['targetId'] as String).toList());
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
            onPressed: () {
              // TODO: gọi hàm đăng xuất
            },
          )
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
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: _acceptedConnectionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final trackedUsers = snapshot.data ?? [];

                  if (trackedUsers.isEmpty) {
                    return const Text("Chưa theo dõi ai cả.");
                  }

                  return ListView.builder(
                    itemCount: trackedUsers.length,
                    itemBuilder: (context, index) {
                      final userId = trackedUsers[index];
                      return Card(
                        child: ListTile(
                          title: Text("Mã người dùng: $userId"),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              // TODO: chuyển đến màn hình xem chỉ số
                            },
                          ),
                        ),
                      );
                    },
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
