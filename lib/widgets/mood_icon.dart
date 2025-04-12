// lib/widgets/mood_icon.dart
import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodIcon extends StatelessWidget {
  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodIcon({
    Key? key,
    required this.mood,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: isSelected ? 30 : 25,
        backgroundColor: isSelected ? mood.color : Colors.white, // ✅ FIXED
        child: Text(
          mood.emoji, // ✅ FIXED: Lấy emoji từ mood object
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
