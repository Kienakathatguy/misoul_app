import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> saveMessageToFirebase({
    required String role,
    required String text,
    required int conversationId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final conversationRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('conversations')
        .doc(conversationId.toString());

    await conversationRef.set({
      'conversationId': conversationId,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await conversationRef.collection('messages').add({
      'role': role,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
