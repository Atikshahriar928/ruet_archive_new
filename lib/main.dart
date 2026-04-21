import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'managers/notification_manager.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/complete_profile_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 1. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Set up Notification Manager (Non-blocking)
    NotificationManager.initialize().then((_) {
      debugPrint("Notification Manager Initialized");
    }).catchError((e) {
      debugPrint("Notification Manager Init Error: $e");
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RUET Archive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
          primary: const Color(0xFF10B981),
        ),
        useMaterial3: true,
      ),
      // Use StreamBuilder to automatically handle Login/Logout state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))));
          }
          
          if (snapshot.hasData) {
            // User is logged in
            return const HomeScreen();
          }

          // User is logged out
          return LoginScreen(
            onLoginSuccess: () {
              // Navigation is handled automatically by StreamBuilder
            },
            onSignUpSuccess: (email, password) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CompleteProfileScreen(
                    onComplete: () {
                      // Profile complete - navigation handled by StreamBuilder
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
