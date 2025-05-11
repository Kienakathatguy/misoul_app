import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'family_chatbot_screen.dart';

class FamilyTherapyChatApp extends StatefulWidget {
  const FamilyTherapyChatApp({super.key});

  @override
  State<FamilyTherapyChatApp> createState() => _FamilyTherapyChatAppState();
}

class _FamilyTherapyChatAppState extends State<FamilyTherapyChatApp> {
  final currentUser = FirebaseAuth.instance.currentUser;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _threads = [];

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('familyChatThreads')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('lastUpdated', descending: true)
        .get();

    setState(() {
      _threads = snapshot.docs;
    });
  }

  Future<void> _createNewThread() async {
    final newThread = await FirebaseFirestore.instance.collection('familyChatThreads').add({
      'userId': currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    _loadThreads();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FamilyChatbotScreen(threadId: newThread.id)),
    );
  }

  void _navigateToThread(String threadId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FamilyChatbotScreen(threadId: threadId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: const Color(0xFF1A0B2E),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Trò chuyện với AI',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.home, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        '${_threads.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Cuộc trò chuyện',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 60),
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  child: _threads.isEmpty
                      ? const Center(
                    child: Text(
                      "Chưa có cuộc trò chuyện nào",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    itemCount: _threads.length,
                    itemBuilder: (context, index) {
                      final thread = _threads[index];
                      final timestamp = (thread['lastUpdated'] as Timestamp?)?.toDate();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _navigateToThread(thread.id),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8E3FFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Cuộc trò chuyện với AI",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(
                                        timestamp != null
                                            ? "Cập nhật lúc ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}"
                                            : "Không rõ thời gian",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 355,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _createNewThread,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
