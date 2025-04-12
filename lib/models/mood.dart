import 'package:flutter/material.dart';

class Mood {
  final String name;
  final String emoji;
  final Color color;
  final int index;
  final bool isCustomEmoji;
  final String? emojiPath;

  const Mood(
      this.name,
      this.emoji,
      this.color,
      this.index, {
        this.isCustomEmoji = false,
        this.emojiPath,
      });

  // Default moods with built-in emojis
  static const Mood veryHappy = Mood('Rất vui', '😊', Color(0xFFFF4D79), 0);
  static const Mood happy = Mood('Vui', '😊', Color(0xFFFF7A9C), 1);
  static const Mood neutral = Mood('Bình thường', '😐', Color(0xFFFFB0C1), 2);
  static const Mood sad = Mood('Buồn', '😔', Color(0xFF8B5CF6), 3);
  static const Mood verySad = Mood('Rất buồn', '😢', Color(0xFF4C1D95), 4);

  // Custom moods with image emojis
  static const Mood veryHappy_custom = Mood(
    'Rất vui',
    '',
    Color(0xFFFFFFFF),
    5,
    isCustomEmoji: true,
    emojiPath: 'assets/emojis/Very_Happy.png',
  );

  static const Mood happy_custom = Mood(
    'Vui',
    '',
    Color(0xFFFFFFFF),
    6,
    isCustomEmoji: true,
    emojiPath: 'assets/emojis/Happy.png',
  );

  static const Mood neutral_custom = Mood(
    'Bình thường',
    '',
    Color(0xFFFDFDFD),
    7,
    isCustomEmoji: true,
    emojiPath: 'assets/emojis/Neutral.png',
  );

  static const Mood sad_custom = Mood(
    'Buồn',
    '',
    Color(0xFFFFFFFF),
    8,
    isCustomEmoji: true,
    emojiPath: 'assets/emojis/Sad.png',
  );

  static const Mood verySad_custom = Mood(
    'Rất buồn',
    '',
    Color(0xFFFFFFFF),
    9,
    isCustomEmoji: true,
    emojiPath: 'assets/emojis/Very_sad.png',
  );

  // Danh sách tất cả các mood (cho hiển thị / tra cứu index)
  static List<Mood> allMoods = [
    veryHappy,
    happy,
    neutral,
    sad,
    verySad,
    veryHappy_custom,
    happy_custom,
    neutral_custom,
    sad_custom,
    verySad_custom,
  ];

  // Tìm Mood từ index
  static Mood fromIndex(int index) {
    return allMoods.firstWhere((m) => m.index == index, orElse: () => neutral);
  }
}
