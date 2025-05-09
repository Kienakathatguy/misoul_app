import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserMoodService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> saveTodayMood(int moodIndex) async {
    final now = DateTime.now();
    await saveMoodForDate(now, moodIndex);
  }

  static Future<void> saveMoodForDate(DateTime date, int moodIndex) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final moodDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .doc(moodDate)
        .set({
      'moodIndex': moodIndex,
      'createdAt': Timestamp.fromDate(date),
    });
  }

  static Future<int?> getTodayMoodIndex() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final today = DateTime.now();
    final moodDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .doc(moodDate)
        .get();

    if (doc.exists && doc.data()?['moodIndex'] != null) {
      return doc.data()!['moodIndex'];
    }
    return null;
  }

  static Future<Map<String, int>> loadMonthMoods(DateTime date) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    Map<String, int> moods = {};
    for (var doc in snapshot.docs) {
      moods[doc.id] = doc.data()['moodIndex'];
    }

    return moods;
  }
}
