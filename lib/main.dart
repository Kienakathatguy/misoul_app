import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:misoul_fixed_app/screens/home_screen.dart';
import 'package:misoul_fixed_app/screens/healing_screen.dart';
import 'package:misoul_fixed_app/screens/imu_screen.dart';
import 'package:misoul_fixed_app/screens/login_screen.dart';
import 'package:misoul_fixed_app/screens/voice_recorder.dart';
import 'package:misoul_fixed_app/screens/mood_tracker.dart';
import 'package:misoul_fixed_app/screens/therapy_chat_app.dart';
import 'package:misoul_fixed_app/screens/time_up_screen.dart';
import 'package:misoul_fixed_app/screens/scheduler_screen.dart';
import 'package:firebase_core/firebase_core.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  runApp(MisoulApp());

  Future.delayed(Duration(seconds: 3), () {
    FlutterNativeSplash.remove(); // Tắt splash screen sau 3 giây
  });
}

class MisoulApp extends StatelessWidget {
  const MisoulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MISOUL App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/healing': (context) => HealingScreen(),
        '/login': (context) => LoginScreen(),
        '/chatbot': (context) => TherapyChatApp(),
        '/imu': (context) => const IMUScreen(),
        '/scheduler': (context) => SchedulerScreen(),
        '/mood_tracker': (context) => MoodTrackerScreen(),
        '/settings': (context) => const PlaceholderScreen(title: 'Cài đặt'),
        '/time_up': (context) => TimeUpScreen(),
      },
    );
  }
}

// Màn hình placeholder để test điều hướng
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Đang phát triển...')),
    );
  }
}
