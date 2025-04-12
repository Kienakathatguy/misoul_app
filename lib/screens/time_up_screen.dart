import 'package:flutter/material.dart';

class TimeUpScreen extends StatelessWidget {
  const TimeUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA87EF0), // ✅ Background tím
      body: Stack(
        children: [
          // ✅ Ảnh trang trí nền phía sau
          Positioned(
            top: 0,
            left: 0,
            right: 0, // Đảm bảo tràn toàn bộ chiều ngang
            child: Image.asset(
              'assets/images/background_decor_out_of_chat.png',
              fit: BoxFit.cover, // Có thể đổi thành .fitWidth nếu muốn chiều ngang vừa màn
              alignment: Alignment.topLeft,
            ),
          ),

          // ✅ Ảnh chính giữa tràn 2 bên
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2, // Căn từ trên xuống
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/out_of_chat.png',
              fit: BoxFit.fitWidth,
              width: double.infinity, // ⬅️ Bắt buộc dùng để tràn 2 bên
            ),
          ),

          // ✅ Khối trắng ở dưới
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 340,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(60),
                  topRight: Radius.circular(60),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  children: [
                    const Text(
                      'Rất tiếc!\nĐã hết thời gian',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A0B2E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '90 phút trò chuyện của bạn đã hết!\nHẹn gặp lại bạn hôm khác nhé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3F3F3F),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A0B2E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: const Text(
                          'Quay về trang chủ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
