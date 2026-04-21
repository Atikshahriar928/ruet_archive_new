import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import 'database_manager.dart';
import 'notification_manager.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? "251166023993-q8b4v1sbvmdj4hnjdtkch6seaea6288a.apps.googleusercontent.com" : null,
  );

  // Background sync to prevent blocking the UI
  void _startBackgroundSync(User user) {
    _syncProfile(user);
    NotificationManager.updateToken();
  }

  Future<void> _syncProfile(User user) async {
    try {
      final exists = await DatabaseManager.checkUserProfileExists(user.uid);
      if (!exists) {
        final profile = UserProfile(
          uid: user.uid,
          fullName: user.displayName ?? user.email?.split('@').first ?? "User",
          profileImageBase64: user.photoURL,
        );
        await DatabaseManager.saveUserProfile(profile);
      }
    } catch (e) {
      debugPrint("AUTH_DEBUG: Error during profile sync: $e");
    }
  }

  // Google Sign-In logic
  Future<void> signInWithGoogle(Function(bool success, String? message) onResult) async {
    try {
      debugPrint("AUTH_DEBUG: Google Sign-In started");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        onResult(false, "Sign in aborted by user");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        // Run sync in background - don't await!
        _startBackgroundSync(result.user!);
        debugPrint("AUTH_DEBUG: Google Sign-In Success, background sync started");
        onResult(true, null);
      }
    } catch (e) {
      debugPrint("AUTH_DEBUG: Google Sign-In Error: $e");
      onResult(false, e.toString());
    }
  }

  // Email Sign Up
  Future<void> signUp(String email, String password, Function(bool success, String? message) onResult) async {
    try {
      debugPrint("AUTH_DEBUG: Sign-Up attempt for $email");
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));

      if (result.user != null) {
        _startBackgroundSync(result.user!);
        onResult(true, null);
      }
    } on FirebaseAuthException catch (e) {
      onResult(false, e.message);
    } catch (e) {
      onResult(false, "An unexpected error occurred.");
    }
  }

  // Login with Email and Password
  Future<void> login(String email, String password, Function(bool success, String? message) onResult) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));
      
      if (result.user != null) {
        _startBackgroundSync(result.user!);
      }
      onResult(true, null);
    } on FirebaseAuthException catch (e) {
      onResult(false, e.message);
    } catch (e) {
      onResult(false, "An unexpected error occurred.");
    }
  }

  Future<void> logout() async {
    debugPrint("AUTH_DEBUG: Logout initiated...");
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      debugPrint("AUTH_DEBUG: Logout successful.");
    } catch (e) {
      debugPrint("AUTH_DEBUG: Logout Error: $e");
    }
  }

  User? getCurrentUser() => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
