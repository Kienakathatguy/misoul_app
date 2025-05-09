import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chart_data_service.dart';

class EmotionRequestsScreen extends StatefulWidget {
  const EmotionRequestsScreen({super.key});

  @override
  State<EmotionRequestsScreen> createState() => _EmotionRequestsScreenState();
}

class _EmotionRequestsScreenState extends State<EmotionRequestsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _respondToRequest(String requestId, bool accept) async {
    final docRef = FirebaseFirestore.instance.collection('emotion_view_requests').doc(requestId);
    final docSnapshot = await docRef.get();
    final data = docSnapshot.data();
    final timeframe = data?['timeframe'];
    final requesterId = data?['requesterId'];

    if (accept && timeframe != null) {
      await ChartDataService.updateAllChartData();
    }

    await docRef.update({
      'status': accept ? 'accepted' : 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(accept ? 'Đã chấp nhận yêu cầu' : 'Đã từ chối yêu cầu')),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("Không có người dùng hiện tại"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yêu cầu xem biểu đồ cảm xúc"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emotion_view_requests')
            .where('targetUserId', isEqualTo: currentUser!.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(child: Text("Không có yêu cầu nào"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final requesterId = request['requesterId'];
              final timeframe = request['timeframe'] ?? 'ngày';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("Người thân muốn xem biểu đồ cảm xúc theo $timeframe"),
                  subtitle: Text("ID người gửi: $requesterId"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _respondToRequest(request.id, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _respondToRequest(request.id, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
