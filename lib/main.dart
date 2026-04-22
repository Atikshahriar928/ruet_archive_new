import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'managers/notification_manager.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/email_verification_screen.dart';
import 'managers/database_manager.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Use a key to force rebuild the FutureBuilder if needed
  Key _profileCheckKey = UniqueKey();

  void _refreshProfileStatus() {
    setState(() {
      _profileCheckKey = UniqueKey();
    });
  }

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))));
          }
          
          final user = snapshot.data;
          if (user != null) {
            // 1. Check email verification
            if (!user.emailVerified) {
              return EmailVerificationScreen(onVerified: () => setState(() {}));
            }

            // 2. User is logged in and verified, now check profile existence
            return FutureBuilder<bool>(
              key: _profileCheckKey,
              future: DatabaseManager.checkUserProfileExists(user.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))));
                }

                if (profileSnapshot.data == true) {
                  return const HomeScreen();
                } else {
                  return CompleteProfileScreen(
                    onComplete: _refreshProfileStatus,
                  );
                }
              },
            );
          }

          // User is logged out
          return LoginScreen(
            onLoginSuccess: () {}, // Handled by StreamBuilder
            onSignUpSuccess: (email, password) {}, // Handled by StreamBuilder
          );
        },
      ),
    );
  }
}
