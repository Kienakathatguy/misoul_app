import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Map<int, Mood> moodHistory;

  MoodCalendar({Key? key, required this.selectedDate, required this.moodHistory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get days in month
    int daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    // Get current date
    DateTime now = DateTime.now();
    bool isSameMonth = now.year == selectedDate.year && now.month == selectedDate.month;
    int currentDay = now.day;

    // Day names in Vietnamese
    List<String> dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      children: [
        // Day names row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayNames.map((day) =>
                Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
            ).toList(),
          ),
        ),
        SizedBox(height: 10),

        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 15),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 10,
              crossAxisSpacing: 5,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              int day = index + 1;
              Mood? mood = moodHistory[day];

              // Only show emoji for the current day if it has a mood
              bool showEmoji = isSameMonth && day == currentDay && mood != null;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: showEmoji ? mood.color : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: showEmoji
                          ? (mood.isCustomEmoji
                          ? Image.asset(mood.emojiPath!, width: 24, height: 24)
                          : Text(mood.emoji, style: TextStyle(fontSize: 20)))
                          : Text('${day}', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
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

