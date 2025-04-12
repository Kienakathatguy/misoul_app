import 'package:flutter/material.dart';
import 'dart:math';

class AudioWaveform extends StatefulWidget {
  final bool isPlaying;
  const AudioWaveform({required this.isPlaying, Key? key}) : super(key: key);

  @override
  _AudioWaveformState createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<double> _waveData = List.generate(30, (index) => Random().nextDouble());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat();

    _controller.addListener(() {
      if (widget.isPlaying) {
        setState(() {
          _waveData = List.generate(30, (index) => Random().nextDouble());
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPlaying) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 80),
      painter: WavePainter(_waveData),
    );
  }
}

class WavePainter extends CustomPainter {
  final List<double> waveData;
  WavePainter(this.waveData);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final double width = size.width / waveData.length;
    final Path path = Path();

    for (int i = 0; i < waveData.length; i++) {
      double x = i * width;
      double y = (size.height / 2) - (waveData[i] * size.height / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
