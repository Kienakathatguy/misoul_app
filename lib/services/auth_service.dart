import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:misoul_fixed_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  static final _auth = FirebaseAuth.instance;


  static Future<String?> registerWithEmail(String email, String password, String role) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      // Lưu vào Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Tạo profile nếu cần (nếu bạn dùng UserService để tạo các trường khác)
      await UserService.createUserProfileIfNotExists();

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }


  // 🔐 Đăng nhập bằng Email
  static Future<String?> signInWithEmail(String email, String password, String role) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await UserService.createUserProfileIfNotExists();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 🔐 Đăng nhập với Google
  static Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return "Đã huỷ đăng nhập";

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await UserService.createUserProfileIfNotExists();
      return null;
    } catch (e) {
      return "Lỗi Google: $e";
    }
  }

  // 🔐 Đăng nhập với Facebook
  static Future<String?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!;
        final credential = FacebookAuthProvider.credential(accessToken.token);

        await _auth.signInWithCredential(credential);
        await UserService.createUserProfileIfNotExists(); // ✅

        return null;
      } else {
        return "Facebook login bị huỷ";
      }
    } catch (e) {
      return "Lỗi Facebook: $e";
    }
  }
}
