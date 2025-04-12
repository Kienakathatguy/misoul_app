import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class VoiceRecorder extends StatefulWidget {
  @override
  _VoiceRecorderState createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  String? _audioPath;

  // Danh sách lưu lịch sử ghi âm
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> _startRecording() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      String path = "audio_${DateTime.now().millisecondsSinceEpoch}.aac";

      setState(() {
        _isRecording = true;
        _audioPath = path;
      });

      await _recorder.startRecorder(toFile: path);
    } else {
      _showPermissionDialog();
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false; // Cập nhật UI ngay lập tức
    });

    await _recorder.stopRecorder();

    if (_audioPath != null) {
      String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      setState(() {
        _history.insert(0, {
          "file": _audioPath!,
          "time": timestamp,
          "sender": "Bạn", // Thông tin người gửi
          "description": "Hỏi thăm tâm trạng hôm nay",
        });
        _audioPath = null; // Reset đường dẫn file
      });
    }
  }

  Future<void> _playRecording(String path) async {
    await _player.startPlayer(fromURI: path);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Quyền truy cập micro"),
          content: Text("Ứng dụng cần quyền truy cập microphone để ghi âm. Hãy cấp quyền trong cài đặt."),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: Text("Mở cài đặt"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy"),
            ),
          ],
        );
      },
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gửi voice hỏi thăm"),
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () => _navigateTo(context, '/home'), // Nút Home góc phải trên cùng
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _isRecording
                      ? Icon(Icons.stop, color: Colors.red, size: 50)
                      : Icon(Icons.mic, color: Colors.blue, size: 50),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isRecording ? "Dừng ghi âm" : "Bắt đầu ghi âm"),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Expanded(
            child: _history.isEmpty
                ? Center(child: Text("Chưa có lịch sử ghi âm"))
                : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.voicemail, color: Colors.blue),
                    title: Text("${_history[index]["sender"]}: ${_history[index]["description"]}"),
                    subtitle: Text("Thời gian: ${_history[index]["time"]}"),
                    trailing: IconButton(
                      icon: Icon(Icons.play_arrow, color: Colors.green),
                      onPressed: () => _playRecording(_history[index]["file"]!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 🎯 Feature Bar
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
              icon: Icon(Icons.favorite_border, color: Colors.grey),
              onPressed: () => _navigateTo(context, '/imu'),
            ),
          ],
        ),
      ),

      // 🎯 Floating Action Button
      floatingActionButton: Container(
        height: 60,
        width: 60,
        margin: EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          backgroundColor: Color(0xFF1A1A2E),
          child: Icon(Icons.mic, color: Colors.white),
          onPressed: () => {},
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
