import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _firestore = FirebaseFirestore.instance;

  // Tạo hồ sơ người dùng nếu chưa có
  static Future<void> createUserProfileIfNotExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? '',
        'goal': '',
        'avatarUrl': '',
      });
    }
  }

  // Cập nhật tên và mục tiêu
  static Future<void> updateUserProfile({String? displayName, String? goal}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (goal != null) updates['goal'] = goal;

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  // Lấy thông tin người dùng
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }
}
