import 'dart:async';
import 'package:flutter/material.dart';

class CountdownScreen extends StatefulWidget {
  final String exerciseName;
  final Duration duration;
  final DateTime? startTime; // ✅ mới thêm

  const CountdownScreen({
    Key? key,
    required this.exerciseName,
    required this.duration,
    this.startTime,
  }) : super(key: key);

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late Duration remaining;
  Timer? _timer;
  bool waitingForStart = false;

  @override
  void initState() {
    super.initState();

    if (widget.startTime != null &&
        widget.startTime!.isAfter(DateTime.now().add(const Duration(seconds: 5)))) {
      // Nếu thời gian bắt đầu trong tương lai (sau ít nhất 5s)
      final delay = widget.startTime!.difference(DateTime.now());
      remaining = delay;
      waitingForStart = true;

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (remaining.inSeconds <= 1) {
            _timer?.cancel();
            waitingForStart = false;
            remaining = widget.duration;
            _startMainTimer();
          } else {
            remaining -= const Duration(seconds: 1);
          }
        });
      });
    } else {
      // Bắt đầu ngay
      remaining = widget.duration;
      _startMainTimer();
    }
  }

  void _startMainTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (remaining.inSeconds > 0) {
          remaining -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final title = waitingForStart
        ? "Chờ đến giờ bắt đầu..."
        : (remaining.inSeconds > 0 ? "Đang thực hiện..." : "Hoàn thành!");

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.exerciseName, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 30),
            Text(
              _formatTime(remaining),
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!waitingForStart && remaining.inSeconds == 0)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Quay lại"),
              ),
          ],
        ),
      ),
    );
  }
}
