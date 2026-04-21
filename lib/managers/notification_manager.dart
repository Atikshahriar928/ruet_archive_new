import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'database_manager.dart';

class NotificationManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('NOTI_DEBUG: User granted permission');
    }

    // 2. Initialize Local Notifications (Mobile Only)
    if (!kIsWeb) {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      // Create a High Importance channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', 
        'High Importance Notifications', 
        description: 'This channel is used for important notifications like messages.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 3. Handle Token Refresh automatically
    _messaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token);
    });

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("NOTI_DEBUG: Received foreground message: ${message.notification?.title ?? message.data['title']}");
      if (!kIsWeb) {
        _showLocalNotification(message);
      }
    });
    
    // 5. Subscribe to global topic for posts (Mobile only)
    if (!kIsWeb) {
      await _messaging.subscribeToTopic('all_reports');
      debugPrint("NOTI_DEBUG: Subscribed to all_reports topic");
    }

    // 6. Initial token sync if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      updateToken();
    }
  }

  static Future<void> updateToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("NOTI_DEBUG: Error getting token: $e");
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await DatabaseManager.updateFcmToken(uid, token);
      debugPrint("NOTI_DEBUG: Token synced to Firestore for $uid");
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    if (kIsWeb) return;
    
    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];

    if (title != null || body != null) {
      _localNotifications.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    }
  }
}

// Background handler must be top-level and annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("NOTI_DEBUG: Handling background message: ${message.messageId}");
  
  // To show a notification with sound when app is closed/background (Data-only messages)
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initSettings);

  String? title = message.notification?.title ?? message.data['title'];
  String? body = message.notification?.body ?? message.data['body'];

  if (title != null || body != null) {
    await localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
      ),
    );
  }
}
