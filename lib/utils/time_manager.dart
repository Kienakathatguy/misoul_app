import 'package:shared_preferences/shared_preferences.dart';

class TimeManager {
  static const int maxMinutes = 90;
  static const String _keyMinutes = 'chat_minutes';
  static const String _keyDate = 'chat_date';

  static Future<void> initTodayTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final storedDate = prefs.getString(_keyDate);

    if (storedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyMinutes, 0);
    }
  }

  static Future<int> getUsedMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    await initTodayTime();
    return prefs.getInt(_keyMinutes) ?? 0;
  }

  static Future<void> addMinuteUsed(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await initTodayTime();
    int current = prefs.getInt(_keyMinutes) ?? 0;
    await prefs.setInt(_keyMinutes, current + minutes);
  }

  static Future<bool> isTimeUp() async {
    final used = await getUsedMinutes();
    return used >= maxMinutes;
  }

  static Future<int> getRemaining() async {
    final used = await getUsedMinutes();
    return maxMinutes - used;
  }
}
