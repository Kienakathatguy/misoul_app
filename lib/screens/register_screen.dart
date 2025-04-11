import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool agreeToTerms = false;
  bool showEmailError = false;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  void _register() async {
    setState(() {
      showEmailError = !isValidEmail(_emailController.text.trim());
    });

    if (!showEmailError && agreeToTerms) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Đăng ký thành công!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String message = "Đã xảy ra lỗi";
        if (e.code == 'email-already-in-use') {
          message = "Email này đã được đăng ký!";
        } else if (e.code == 'weak-password') {
          message = "Mật khẩu quá yếu (tối thiểu 6 ký tự)";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi không xác định: $e")),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Đăng nhập Google: ${userCredential.user?.email ?? 'Không có email'}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Đăng nhập Google thất bại")),
      );
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final credential = FacebookAuthProvider.credential(result.accessToken!.token);
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Đăng nhập Facebook: ${userCredential.user?.email ?? 'Không có email'}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Đăng nhập Facebook bị huỷ")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Đăng nhập Facebook thất bại")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Stack(
                children: [
                  Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(80)),
                    ),
                  ),
                  Positioned.fill(
                    top: 70,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 65,
                        height: 65,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text("Đăng ký tài khoản", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 28),

              // Email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Email của bạn",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: showEmailError ? Colors.pink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              if (showEmailError)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 32, right: 32),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.purple),
                      SizedBox(width: 8),
                      Text("Email không hợp lệ!", style: TextStyle(color: Colors.purple)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Password
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Nhập mật khẩu...",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: const Icon(Icons.visibility_off),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Checkbox
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Checkbox(
                      value: agreeToTerms,
                      onChanged: (val) => setState(() => agreeToTerms = val ?? false),
                      activeColor: Colors.black,
                    ),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "Tôi đồng ý với ",
                          children: [
                            TextSpan(
                              text: "Điều khoản và điều kiện",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Đăng ký
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B0039),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Đăng ký", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("hoặc đăng ký với", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),

              // Social login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _signInWithFacebook,
                    child: const SocialButton(icon: Icons.facebook),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _signInWithGoogle,
                    child: const SocialButton(icon: Icons.g_mobiledata),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Bạn đã có tài khoản?"),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text("Đăng nhập ngay"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final IconData icon;

  const SocialButton({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEAE2F3),
      ),
      child: Icon(icon, color: Colors.black),
    );
  }
}
