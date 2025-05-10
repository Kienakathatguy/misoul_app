import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IMUScreen extends StatefulWidget {
  const IMUScreen({super.key});

  @override
  State<IMUScreen> createState() => _IMUScreenState();
}

class _IMUScreenState extends State<IMUScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Chưa đăng nhập")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTopMessageBox(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hôm nay", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(Icons.android, size: 20),
                      SizedBox(width: 6),
                      Text("Mới nhất"),
                      Icon(Icons.arrow_drop_down),
                    ],
                  )
                ],
              ),
            ),
            Expanded(child: _buildMessageList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 8),
          const Text(
            "I MISS U",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTopMessageBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.pink.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Colors.pink),
              SizedBox(width: 8),
              Text("I miss you", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "Có những người đang gửi lời yêu thương tới bạn",
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messagesRef = FirebaseFirestore.instance
        .collection('imuMessages')
        .where('receiverId', isEqualTo: currentUser!.uid)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: messagesRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final senderName = data['senderName'] ?? '[Tên]';
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final timeText = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            "$senderName đã gửi lời thương yêu tới bạn",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _respondToMessage(docs[index].id, "I'm Okay 😊"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.pink,
                              ),
                              child: const Text("I’m Okay 😊"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _respondToMessage(docs[index].id, "I need you 😢"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade200,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("I need you 😢"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _respondToMessage(String messageId, String responseText) async {
    await FirebaseFirestore.instance.collection('imuResponses').add({
      'messageId': messageId,
      'response': responseText,
      'responderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã phản hồi: $responseText")),
    );
  }
}
