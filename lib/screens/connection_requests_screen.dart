import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectionRequestsScreen extends StatelessWidget {
  const ConnectionRequestsScreen({super.key});

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
      body: StreamBuilder<QuerySnapshot>(
        stream: requestsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Không có yêu cầu nào."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final requesterId = data['requesterId'];

              return Card(
                child: ListTile(
                  title: Text("Người thân ID: $requesterId"),
                  subtitle: Text("Đang chờ xác nhận"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('connection_requests')
                              .doc(docId)
                              .update({'status': 'accepted'});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('connection_requests')
                              .doc(docId)
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
    );
  }
}
