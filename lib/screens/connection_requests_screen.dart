import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Dùng để sao chép mã

class ConnectionRequestsScreen extends StatelessWidget {
  const ConnectionRequestsScreen({super.key});

  Future<void> _acceptRequest(String docId, String requesterId, String currentUserId) async {
    final connectionRequests = FirebaseFirestore.instance.collection('connection_requests');
    final userConnections = FirebaseFirestore.instance.collection('user_connections');

    // Cập nhật trạng thái yêu cầu
    await connectionRequests.doc(docId).update({'status': 'accepted'});

    // Lưu kết nối chiều 1: Người thân → Người dùng
    await userConnections.add({
      'familyId': requesterId,
      'userId': currentUserId,
      'status': 'accepted',
      'connectedAt': FieldValue.serverTimestamp(),
    });

    // Lưu kết nối chiều 2: Người dùng → Người thân
    await userConnections.add({
      'familyId': currentUserId,
      'userId': requesterId,
      'status': 'accepted',
      'connectedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    final requestsRef = FirebaseFirestore.instance
        .collection('connection_requests')
        .where('targetId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending');

    return Scaffold(
      appBar: AppBar(title: const Text("Yêu cầu kết nối")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Mã người dùng của bạn: ${currentUser.uid}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: currentUser.uid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã sao chép mã người dùng")),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: requestsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("Không có yêu cầu nào."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final requesterId = data['requesterId'];

                    return Card(
                      child: ListTile(
                        title: Text("Người thân ID: $requesterId"),
                        subtitle: const Text("Đang chờ xác nhận"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptRequest(doc.id, requesterId, currentUser.uid),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('connection_requests')
                                    .doc(doc.id)
                                    .update({'status': 'rejected'});
                              },
                            ),
                          ],
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
    );
  }
}
