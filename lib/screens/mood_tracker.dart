import 'package:flutter/material.dart';
import 'package:misoul_fixed_app/widgets/mood_chart.dart';
import 'package:misoul_fixed_app/widgets/mood_calendar.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import '../services/user_mood_service.dart';


class MoodTrackerScreen extends StatefulWidget {
  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  Map<int, Mood> moodHistory = {
    1: Mood.veryHappy,
    2: Mood.neutral,
    3: Mood.sad,
    4: Mood.verySad,
    5: Mood.veryHappy,
    6: Mood.happy,
  };

  TabController? _tabController;
  String _viewType = "Tháng"; // Default view is month

  final List<Mood> moodOptions = [
    Mood.veryHappy_custom,
    Mood.happy_custom,
    Mood.neutral_custom,
    Mood.sad_custom,
    Mood.verySad_custom,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.index = 1; // Start with "Tháng" selected
    _tabController!.addListener(() {
      setState(() {
        switch (_tabController!.index) {
          case 0:
            _viewType = "Tuần";
            break;
          case 1:
            _viewType = "Tháng";
            break;
          case 2:
            _viewType = "Năm";
            break;
        }
      });
    });
    _loadMonthMood();
  }

  Future<void> _loadMonthMood() async {
    final moodMap = await UserMoodService.loadMonthMoods(selectedDate);

    setState(() {
      moodHistory = {};
      moodMap.forEach((dateStr, moodIndex) {
        final date = DateTime.parse(dateStr);
        moodHistory[date.day] = moodOptions.firstWhere(
              (m) => m.index == moodIndex,
          orElse: () => Mood.neutral_custom,
        );
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Update the addMood method to only set mood for the current day
  void addMood(Mood mood) async {
    final now = DateTime.now();

    if (selectedDate.year == now.year && selectedDate.month == now.month) {
      setState(() {
        moodHistory[now.day] = mood;
      });

      await UserMoodService.saveTodayMood(mood.index); // ✅ Lưu mood vào Firestore
    }
  }


  void changeMonth(int offset) {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + offset);
    });
  }

  void _showMoodChart() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Mood Chart"),
          content: Container(
            height: 300,
            width: 300,
            child: MoodChart(moodData: moodHistory.values.map((m) => m.index + 1).toList()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng"),
            ),
          ],
        );
      },
    );
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
          backgroundColor: Color(0xFFFF4D79),
          elevation: 0,
        ),
      ),
      body: Column(
        children: [
          // Top pink section with status bar time
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: Color(0xFFFF4D79),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Status bar time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('H:mm').format(DateTime.now()),
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
                      onTap: () => Navigator.pop(context), // Make back button work
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
                      'Theo dõi cảm xúc',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    // Added home button
                    IconButton(
                      icon: Icon(Icons.home, color: Colors.white),
                      onPressed: () => _navigateTo(context, '/home'),
                    ),
                    IconButton(
                      icon: Icon(Icons.bar_chart, color: Colors.white),
                      onPressed: _showMoodChart,
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Mood selection
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: moodOptions.map((mood) {
                          return GestureDetector(
                            onTap: () => addMood(mood),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: mood.color,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: mood.isCustomEmoji
                                    ? Image.asset(mood.emojiPath!, width: 30, height: 30)
                                    : Text(mood.emoji, style: TextStyle(fontSize: 24)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                // How do you feel today text
                Text(
                  "Hôm nay bạn cảm thấy như thế nào",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Tab selector (Week, Month, Year) - Made bigger with 1/3 indicator
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            height: 50, // Increased height
            decoration: BoxDecoration(
              color: Color(0xFFFF4D79),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              // Custom indicator that covers 1/3 of the tab
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorSize: TabBarIndicatorSize.tab, // Makes indicator cover the tab
              labelPadding: EdgeInsets.zero, // Remove padding to ensure indicator covers 1/3
              labelColor: Color(0xFFFF4D79),
              unselectedLabelColor: Colors.white,
              labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Bigger text
              tabs: [
                Tab(text: "Tuần"),
                Tab(text: "Tháng"),
                Tab(text: "Năm"),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Month navigation with animation
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.1, 0.0),
                    end: Offset(0.0, 0.0),
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Row(
              key: ValueKey<DateTime>(selectedDate),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, size: 30, color: Colors.black),
                  onPressed: () => changeMonth(-1),
                ),
                Text(
                  "Tháng ${selectedDate.month} ${selectedDate.year}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, size: 30, color: Colors.black),
                  onPressed: () => changeMonth(1),
                ),
              ],
            ),
          ),

          // Calendar with animation
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: MoodCalendar(
                key: ValueKey<DateTime>(selectedDate),
                selectedDate: selectedDate,
                moodHistory: moodHistory,
              ),
            ),
          ),

          // Bottom navigation bar
          Container(
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
                // I MISS YOU button (replaced home button)
                IconButton(
                  icon: Icon(Icons.favorite_border, color: Colors.grey),
                  onPressed: () => _navigateTo(context, '/imu'),
                ),
                // Chatbot button
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
                  onPressed: () => _navigateTo(context, '/chatbot'),
                ),
                SizedBox(width: 50), // Space for FAB
                // Healing with music button
                IconButton(
                  icon: Icon(Icons.music_note, color: Colors.grey),
                  onPressed: () => _navigateTo(context, '/healing'),
                ),
                // Voice recording button
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.grey),
                  onPressed: () => _navigateTo(context, '/voice_recorder'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 60,
        width: 60,
        margin: EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          backgroundColor: Color(0xFF1A1A2E),
          child: Icon(Icons.emoji_emotions, color: Colors.white),
          onPressed: () => {}, // Current screen (mood tracker)
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

