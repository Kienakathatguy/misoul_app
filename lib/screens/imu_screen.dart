import 'package:flutter/material.dart';

class IMUScreen extends StatefulWidget {
  const IMUScreen({super.key});

  @override
  IMUScreenState createState() => IMUScreenState();
}

class IMUScreenState extends State<IMUScreen> {
  Color _lightColor = Colors.grey; // Màu mặc định của ánh sáng
  bool _isBlinking = false; // Trạng thái tránh spam IMU
  List<String> _history = []; // Lịch sử các tín hiệu IMU

  // Hàm bật hiệu ứng ánh sáng (Nhấp nháy 2 lần)
  Future<void> _sendIMU(Color color, String name) async {
    if (_isBlinking) return; // Nếu đang nhấp nháy, không chạy tiếp
    setState(() => _isBlinking = true);

    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 500)); // Chờ 500ms
      if (!mounted) return; // Kiểm tra xem widget còn tồn tại không
      setState(() {
        _lightColor = (_lightColor == Colors.grey) ? color : Colors.grey;
      });
    }

    // Thêm tín hiệu vào lịch sử
    setState(() {
      _history.insert(0, 'Sent by: $name at ${TimeOfDay.now().format(context)}');
      _isBlinking = false;
      _lightColor = Colors.grey; // Reset về màu ban đầu
    });
  }

  // Navigate to different screens
  void _navigateTo(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.blueAccent, // Màu khác thay vì hồng
          elevation: 0,
        ),
      ),
      body: Column(
        children: [
          // Top section with status bar time
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Status bar time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TimeOfDay.now().format(context), // Hiển thị giờ hiện tại
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_alt, color: Colors.white),
                        SizedBox(width: 5),
                        Icon(Icons.wifi, color: Colors.white),
                        SizedBox(width: 5),
                        Icon(Icons.battery_full, color: Colors.white),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Title with back button and home button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // Back button
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    SizedBox(width: 15),
                    Text(
                      'IMU - I Miss U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    // Home button
                    IconButton(
                      icon: Icon(Icons.home, color: Colors.white),
                      onPressed: () => _navigateTo(context, '/home'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // The light circle with AnimatedSwitcher for smooth effect
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              key: ValueKey<Color>(_lightColor),
              duration: const Duration(milliseconds: 500),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lightColor, // Màu thay đổi khi nhận IMU
                boxShadow: [
                  BoxShadow(
                    color: _lightColor.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Nhấn vào người thân để gửi tín hiệu IMU", style: TextStyle(fontSize: 16)),

          // List of family members
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text("Mẹ"),
            trailing: ElevatedButton(
              onPressed: () => _sendIMU(Colors.blue, "Mẹ"), // Blue for mother
              child: const Text("Nhớ bạn 💙"),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.red),
            title: const Text("Bố"),
            trailing: ElevatedButton(
              onPressed: () => _sendIMU(Colors.red, "Bố"), // Red for father
              child: const Text("Nhớ bạn ❤️"),
            ),
          ),

          // History of sent IMUs
          SizedBox(height: 20),
          const Text(
            "Lịch sử tín hiệu IMU",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.history, color: Colors.grey),
                  title: Text(_history[index]),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom navigation bar (feature bar)
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.emoji_emotions, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/mood_tracker'),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/chatbot'),
            ),
            SizedBox(width: 50), // Space for FAB
            IconButton(
              icon: Icon(Icons.music_note, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/healing'),
            ),
            IconButton(
              icon: Icon(Icons.mic, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/voice_recorder'),
            ),
          ],
        ),
      ),

      // Floating action button (IMU signal button)
      floatingActionButton: Container(
        height: 60,
        width: 60,
        margin: EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          backgroundColor: Color(0xFF1A1A2E),
          child: Icon(Icons.favorite, color: Colors.white),
          onPressed: () => {}, // Current screen (IMU tracker)
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
