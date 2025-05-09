import 'package:flutter/material.dart';
import 'package:misoul_fixed_app/widgets/mood_chart.dart';
import 'package:misoul_fixed_app/widgets/mood_calendar.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import '../services/user_mood_service.dart';
import '../services/chart_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodTrackerScreen extends StatefulWidget {
  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  Map<String, Mood> moodHistory = {};
  TabController? _tabController;
  String _viewType = "Tháng";

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
    _tabController!.index = 1;
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
        moodHistory[dateStr] = moodOptions.firstWhere(
              (m) => m.index == moodIndex,
          orElse: () => Mood.neutral_custom,
        );
      });
    });
  }

  void addMood(Mood mood) async {
    final key = DateFormat('yyyy-MM-dd').format(selectedDate);
    setState(() {
      moodHistory[key] = mood;
    });
    await UserMoodService.saveMoodForDate(selectedDate, mood.index);
  }

  void changeMonth(int offset) {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + offset);
      _loadMonthMood();
    });
  }

  void _showMoodChart() {
    String selectedMode = "Tuần";
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<int>>(
          future: ChartDataService.getChartForTimeframe(
            userId: FirebaseAuth.instance.currentUser!.uid,
            timeframe: selectedMode.toLowerCase(),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            List<int> moodData = snapshot.data!;
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Row(
                    children: [
                      const Text("Biểu đồ cảm xúc - "),
                      DropdownButton<String>(
                        value: selectedMode,
                        underline: Container(),
                        items: ["Ngày", "Tuần", "Tháng", "Năm"].map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            selectedMode = value;
                            final newData = await ChartDataService.getChartForTimeframe(
                              userId: FirebaseAuth.instance.currentUser!.uid,
                              timeframe: value.toLowerCase(),
                            );
                            setState(() => moodData = newData);
                          }
                        },
                      ),
                    ],
                  ),
                  content: SizedBox(
                    height: 300,
                    width: 300,
                    child: MoodChart(moodData: moodData, viewType: selectedMode),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đóng"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(backgroundColor: Color(0xFFFF4D79), elevation: 0),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: Color(0xFFFF4D79),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
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
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: moodOptions.map((mood) {
                      return GestureDetector(
                        onTap: () => addMood(mood),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(color: mood.color, shape: BoxShape.circle),
                          child: Center(
                            child: mood.isCustomEmoji
                                ? Image.asset(mood.emojiPath!, width: 30, height: 30)
                                : Text(mood.emoji, style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "Hôm nay bạn cảm thấy như thế nào",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            height: 50,
            decoration: BoxDecoration(color: Color(0xFFFF4D79), borderRadius: BorderRadius.circular(30)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
              labelColor: Color(0xFFFF4D79),
              unselectedLabelColor: Colors.white,
              labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              tabs: [Tab(text: "Tuần"), Tab(text: "Tháng"), Tab(text: "Năm")],
            ),
          ),
          SizedBox(height: 20),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: Offset(0.1, 0.0), end: Offset(0.0, 0.0)).animate(animation),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey<DateTime>(selectedDate),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, size: 30, color: Colors.black),
                  onPressed: () => changeMonth(-1),
                ),
                Text("Tháng ${selectedDate.month} ${selectedDate.year}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.chevron_right, size: 30, color: Colors.black),
                  onPressed: () => changeMonth(1),
                ),
              ],
            ),
          ),
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
          Container(
            height: 60,
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2)),
            ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: Icon(Icons.favorite_border, color: Colors.grey), onPressed: () => _navigateTo(context, '/imu')),
                IconButton(icon: Icon(Icons.chat_bubble_outline, color: Colors.grey), onPressed: () => _navigateTo(context, '/chatbot')),
                SizedBox(width: 50),
                IconButton(icon: Icon(Icons.music_note, color: Colors.grey), onPressed: () => _navigateTo(context, '/healing')),
                IconButton(icon: Icon(Icons.mic, color: Colors.grey), onPressed: () => _navigateTo(context, '/voice_recorder')),
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
          onPressed: () => {},
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
