import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';

class MoodCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Map<String, Mood> moodHistory;

  MoodCalendar({Key? key, required this.selectedDate, required this.moodHistory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get number of days in the selected month
    int daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // Day names in Vietnamese
    List<String> dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      children: [
        // Day header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayNames.map((day) => Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            )).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 10,
              crossAxisSpacing: 5,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              int day = index + 1;
              DateTime thisDay = DateTime(selectedDate.year, selectedDate.month, day);
              String key = DateFormat('yyyy-MM-dd').format(thisDay);
              Mood? mood = moodHistory[key];

              bool showEmoji = mood != null;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: showEmoji ? mood!.color : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: showEmoji
                          ? (mood!.isCustomEmoji
                          ? Image.asset(mood.emojiPath!, width: 24, height: 24)
                          : Text(mood.emoji, style: const TextStyle(fontSize: 20)))
                          : Text(
                        '$day',
                        style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
