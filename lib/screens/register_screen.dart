import 'package:flutter/material.dart';
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

  void _register() {
    setState(() {
      showEmailError = !isValidEmail(_emailController.text.trim());
    });

    if (!showEmailError && agreeToTerms) {
      // TODO: Firebase Register logic here
      print("Registering user...");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: Column(
        children: [
          // Vòng cong trên + logo
          Stack(
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(80),
                  ),
                ),
              ),
              Positioned.fill(
                top: 70,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'assets/images/logo.png', // Thay bằng logo của bạn
                    width: 65,
                    height: 65,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            "Đăng ký tài khoản",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 28),

          // Email field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "Địa chỉ email/SĐT",
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
              onChanged: (_) {
                if (showEmailError) {
                  setState(() => showEmailError = false);
                }
              },
            ),
          ),
          if (showEmailError)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 32, right: 32),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.purple),
                  SizedBox(width: 8),
                  Text(
                    "Email không hợp lệ!",
                    style: TextStyle(color: Colors.purple),
                  ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Checkbox + điều khoản
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
                    style: TextStyle(fontSize: 14),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Đăng ký button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B0039),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Đăng ký", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Chuyển về đăng nhập
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Bạn đã có tài khoản?"),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đăng nhập ngay"),
              )
            ],
          ),
        ],
      ),
    );
  }
}
