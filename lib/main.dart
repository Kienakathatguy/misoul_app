import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:misoul_fixed_app/screens/home_screen.dart';
import 'package:misoul_fixed_app/screens/healing_screen.dart';
import 'package:misoul_fixed_app/screens/imu_screen.dart';
import 'package:misoul_fixed_app/screens/login_screen.dart';
import 'package:misoul_fixed_app/screens/mood_tracker.dart';
import 'package:misoul_fixed_app/screens/therapy_chat_app.dart';
import 'package:misoul_fixed_app/screens/time_up_screen.dart';
import 'package:misoul_fixed_app/screens/scheduler_screen.dart';
import 'package:misoul_fixed_app/screens/role_selection_screen.dart';
import 'package:misoul_fixed_app/screens/home_for_family_screen.dart';
import 'package:misoul_fixed_app/screens/connection_requests_screen.dart';
import 'package:misoul_fixed_app/screens/emotion_requests_screen.dart';
import 'package:misoul_fixed_app/screens/connected_family_screen.dart';
import 'package:misoul_fixed_app/screens/emotion_chart_family_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';


Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  FlutterNativeSplash.remove(); // ✅ Gọi sau khi setup xong
  runApp(MisoulApp());
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
        '/register': (context) => const RoleSelectionScreen(),
        'role_selection': (context) => const RoleSelectionScreen(),
        '/home_family': (context) => const HomeForFamilyScreen(),
        '/home': (context) => const HomeScreen(),
        '/connection_requests': (context) => const ConnectionRequestsScreen(),
        '/emotion_requests': (context) => const EmotionRequestsScreen(),
        '/connected_family': (context) => const ConnectedFamilyScreen(),
        '/emotion_chart': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EmotionChartScreen(
            userId: args['userId'],
            timeframe: args['timeframe'],
          );
        },
        '/healing': (context) => HealingScreen(),
        '/login': (context) => LoginScreen(),
        '/chatbot': (context) => TherapyChatApp(),
        '/imu': (context) => IMUScreen(),
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
