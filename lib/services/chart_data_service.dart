import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChartDataService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, int>> _loadMoodsForUser(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .get();

    Map<String, int> moodMap = {};
    for (var doc in snapshot.docs) {
      moodMap[doc.id] = doc.data()['moodIndex'];
    }
    return moodMap;
  }

  static Future<List<int>> getChartForTimeframe({
    required String userId,
    required String timeframe,
    DateTime? referenceDate,
  }) async {
    final moods = await _loadMoodsForUser(userId);
    final now = referenceDate ?? DateTime.now();

    String _dateStr(DateTime date) =>
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    if (timeframe == "ngày") {
      final key = _dateStr(now);
      return [moods[key] != null ? moods[key]! + 1 : 3];
    }

    if (timeframe == "tuần") {
      final start = now.subtract(Duration(days: now.weekday - 1));
      return List.generate(7, (i) {
        final date = start.add(Duration(days: i));
        final key = _dateStr(date);
        return moods[key] != null ? moods[key]! + 1 : 3;
      });
    }

    if (timeframe == "tháng") {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      return List.generate(daysInMonth, (i) {
        final date = DateTime(now.year, now.month, i + 1);
        final key = _dateStr(date);
        return moods[key] != null ? moods[key]! + 1 : 3;
      });
    }

    if (timeframe == "năm") {
      return List.generate(12, (i) {
        int sum = 0, count = 0;
        for (int d = 1; d <= 31; d++) {
          try {
            final date = DateTime(now.year, i + 1, d);
            final key = _dateStr(date);
            if (moods.containsKey(key)) {
              sum += moods[key]! + 1;
              count++;
            }
          } catch (_) {}
        }
        return count > 0 ? (sum ~/ count) : 3;
      });
    }

    return [3]; // fallback
  }

  // ✅ Thêm method này vào BÊN TRONG class
  static Future<void> updateAllChartData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (final timeframe in ['ngày', 'tuần', 'tháng', 'năm']) {
      final chartData = await getChartForTimeframe(
        userId: user.uid,
        timeframe: timeframe,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chartData')
          .doc('moodChart')
          .set({
        timeframe: chartData,
      }, SetOptions(merge: true));
    }
  }
}
