import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IMissUScreen extends StatefulWidget {
  final String targetUserId;
  const IMissUScreen({super.key, required this.targetUserId});

  @override
  State<IMissUScreen> createState() => _IMissUScreenState();
}

class _IMissUScreenState extends State<IMissUScreen> {
  int messageCount = 0;
  bool isPressed = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _sendLoveMessage() async {
    setState(() {
      isPressed = true;
      messageCount++;
    });

    final senderName = currentUser?.displayName ?? "Người thân";

    await FirebaseFirestore.instance.collection('imuMessages').add({
      'senderId': currentUser!.uid,
      'senderName': senderName,
      'receiverId': widget.targetUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          isPressed = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã gửi lời yêu thương 💗")),
    );
  }

  void _showResponsesDialog() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final messages = await FirebaseFirestore.instance
        .collection('imuMessages')
        .where('senderId', isEqualTo: currentUser!.uid)
        .where('receiverId', isEqualTo: widget.targetUserId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .get();

    final messageIds = messages.docs.map((doc) => doc.id).toList();

    if (messageIds.isEmpty) {
      _showAlert("Trạng thái", "Bạn chưa gửi lời yêu thương nào hôm nay.");
      return;
    }

    final responses = await FirebaseFirestore.instance
        .collection('imuResponses')
        .where('messageId', whereIn: messageIds.length > 10 ? messageIds.sublist(0, 10) : messageIds)
        .get();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Phản hồi hôm nay"),
        content: SizedBox(
          width: double.maxFinite,
          child: responses.docs.isEmpty
              ? const Text("Người thân của bạn chưa phản hồi.")
              : ListView(
            shrinkWrap: true,
            children: responses.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final responseText = data['response'] ?? "";
              final time = (data['timestamp'] as Timestamp?)?.toDate();
              final timeStr = time != null
                  ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"
                  : "Không rõ";

              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(responseText),
                subtitle: Text("Phản hồi lúc $timeStr"),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
        ],
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'I MISS U',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bấm nút để gửi lời yêu thương tới\nngười thân của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.3),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _sendLoveMessage,
                child: AnimatedScale(
                  scale: isPressed ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFC0CB),
                        ),
                      ),
                      Container(
                        width: 170,
                        height: 170,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF8DA1),
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.favorite, size: 60, color: Color(0xFFFF4D6D)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Hôm nay bạn đã gửi $messageCount lời yêu thương\ntới ${widget.targetUserId}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.3),
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('TÂM TRẠNG: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(Icons.sentiment_neutral, size: 20),
                  SizedBox(width: 4),
                  Text('BÌNH THƯỜNG', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _showResponsesDialog,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: const BorderSide(color: Color(0xFF121212)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Kiểm tra trạng thái', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildSentMessagesList()),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentMessagesList() {
    final messagesRef = FirebaseFirestore.instance
        .collection('imuMessages')
        .where('senderId', isEqualTo: currentUser!.uid)
        .where('receiverId', isEqualTo: widget.targetUserId)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: messagesRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final messages = snapshot.data!.docs;

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final data = message.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            final timeText = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('imuResponses')
                  .where('messageId', isEqualTo: message.id)
                  .orderBy('timestamp', descending: true)
                  .get(),
              builder: (context, responseSnapshot) {
                final hasResponse = responseSnapshot.hasData && responseSnapshot.data!.docs.isNotEmpty;
                String? responseText;
                String? responseTime;

                if (hasResponse) {
                  final response = responseSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  responseText = response['response'];
                  final responseTimestamp = (response['timestamp'] as Timestamp).toDate();
                  responseTime =
                  "${responseTimestamp.hour.toString().padLeft(2, '0')}:${responseTimestamp.minute.toString().padLeft(2, '0')}";
                }

                return ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.pink),
                  title: Text("Đã gửi lúc $timeText"),
                  subtitle: hasResponse
                      ? Text("👤 Phản hồi: $responseText lúc $responseTime")
                      : const Text("⏳ Chưa có phản hồi"),
                );
              },
            );
          },
        );
      },
    );
  }
}
