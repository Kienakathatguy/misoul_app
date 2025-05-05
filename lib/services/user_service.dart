import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _firestore = FirebaseFirestore.instance;

  // Tạo hồ sơ người dùng nếu chưa có, và đảm bảo 'role' được lấy từ Firestore
  static Future<void> createUserProfileIfNotExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDocRef.get();

    if (!snapshot.exists) {
      // Hồ sơ chưa có → kiểm tra role (đã được lưu từ lúc register)
      final serverUserData = await userDocRef.get();
      final role = serverUserData.data()?['role'] ?? 'Người bệnh';

      await userDocRef.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? '',
        'goal': '',
        'avatarUrl': '',
        'role': role,
      });
    } else {
      // Nếu đã có hồ sơ → đảm bảo 'role' có trong đó
      final data = snapshot.data();
      if (data != null && !data.containsKey('role')) {
        final roleFromRoot = (await userDocRef.get()).data()?['role'] ?? 'Người bệnh';
        await userDocRef.update({'role': roleFromRoot});
      }
    }
  }

  static Future<void> updateUserProfile({String? displayName, String? goal}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (goal != null) updates['goal'] = goal;

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }
}
