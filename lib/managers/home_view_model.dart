import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_manager.dart';

class HomeViewModel extends ChangeNotifier {
  int _unreadMessagesCount = 0;
  int get unreadMessagesCount => _unreadMessagesCount;

  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  StreamSubscription<DocumentSnapshot>? _subscription;

  HomeViewModel() {
    _startListeningToUserCounts();
  }

  void _startListeningToUserCounts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    _subscription = userRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _unreadMessagesCount = data['unreadMessagesCount'] ?? 0;
        _unreadNotificationsCount = data['unreadNotificationsCount'] ?? 0;
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint("HomeViewModel Error: $error");
    });
  }

  Future<void> resetMessageCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await DatabaseManager.resetMessageCount(uid);
      } catch (e) {
        debugPrint("Error resetting message count: $e");
      }
    }
  }

  Future<void> resetNotificationCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await DatabaseManager.resetNotificationCount(uid);
      } catch (e) {
        debugPrint("Error resetting notification count: $e");
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
