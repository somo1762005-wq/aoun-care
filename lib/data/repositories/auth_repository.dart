import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/notification_service.dart';

class AuthRepository {
  // تفعيل خاصية الـ getter الآمن لمنع استدعاء الفايربيز عند بداية التشغيل مباشرة
  fb.FirebaseAuth? get _firebaseAuth {
    if (_isFirebaseEnabled) {
      try {
        return fb.FirebaseAuth.instance;
      } catch (e) {
        debugPrint("Error accessing FirebaseAuth instance: $e");
        return null;
      }
    }
    return null;
  }

  fs.FirebaseFirestore? get _firestore {
    if (_isFirebaseEnabled) {
      try {
        return fs.FirebaseFirestore.instance;
      } catch (e) {
        debugPrint("Error accessing FirebaseFirestore instance in AuthRepository: $e");
        return null;
      }
    }
    return null;
  }

  // Local persistence keys
  static const String keyRole = 'user_role';
  static const String keyEmail = 'user_email';
  static const String keyPhone = 'son_phone';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Streams for Auth State Changes
  final _authStateController = StreamController<String?>.broadcast();
  Stream<String?> get authStateChanges => _authStateController.stream;

  AuthRepository() {
    _init();
  }

  bool get _isFirebaseEnabled {
    try {
      // التحقق الآمن من أن الفايربيز تم تهيئته بنجاح في الـ main
      return fb.FirebaseAuth.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _init() async {
    try {
      if (_isFirebaseEnabled && _firebaseAuth != null) {
        _firebaseAuth!.authStateChanges().listen((user) {
          if (user != null && user.emailVerified) {
            _authStateController.add(user.email);
            // Upload FCM token when authenticated and verified
            NotificationService().uploadFcmToken();
          } else {
            _authStateController.add(null);
          }
        }, onError: (error) {
          debugPrint("Firebase Auth Stream Error: $error");
          _initMockSession();
        });
      } else {
        await _initMockSession();
      }
    } catch (e) {
      debugPrint("Error during AuthRepository init: $e");
      await _initMockSession();
    }
  }

  // دالة منفصلة لإدارة الجلسة المحلية (Mock Mode) بأمان
  Future<void> _initMockSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
    if (isLoggedIn) {
      _authStateController.add(prefs.getString(keyEmail));
    } else {
      _authStateController.add(null);
    }
  }

  Future<void> login(String email, String password) async {
    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        await user.reload(); // Refresh verification status
        final updatedUser = _firebaseAuth!.currentUser;
        if (updatedUser != null && !updatedUser.emailVerified) {
          await _firebaseAuth!.signOut();
          throw fb.FirebaseAuthException(
            code: 'email-not-verified',
            message: 'الرجاء التحقق من بريدك الإلكتروني أولاً. تم إرسال رابط التحقق.',
          );
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyIsLoggedIn, true);
      await prefs.setString(keyEmail, email);
      _authStateController.add(email);
    }
  }

  Future<void> register(String email, String password, String phone) async {
    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        await user.sendEmailVerification();
        // حفظ رقم الهاتف في قاعدة البيانات Firestore
        await _firestore?.collection('users').doc(user.uid).set({
          'email': email,
          'phone': phone,
          'createdAt': fs.FieldValue.serverTimestamp(),
        });
        await _firebaseAuth!.signOut(); // تسجيل الخروج حتى يتم التحقق
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyPhone, phone);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyIsLoggedIn, true);
      await prefs.setString(keyEmail, email);
      await prefs.setString(keyPhone, phone);
      _authStateController.add(email);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyIsLoggedIn);
    await prefs.remove(keyRole);

    if (_isFirebaseEnabled && _firebaseAuth != null) {
      await _firebaseAuth!.signOut();
    } else {
      _authStateController.add(null);
    }
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyRole, role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyRole);
  }

  Future<void> saveEmergencyPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyPhone, phone);

    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        await _firestore?.collection('users').doc(user.uid).set({
          'phone': phone,
        }, fs.SetOptions(merge: true));
      }
    }
  }

  Future<String?> getEmergencyPhone() async {
    final prefs = await SharedPreferences.getInstance();
    String? phone = prefs.getString(keyPhone);

    if (phone == null && _isFirebaseEnabled && _firebaseAuth != null) {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        try {
          final doc = await _firestore?.collection('users').doc(user.uid).get();
          if (doc != null && doc.exists) {
            phone = doc.data()?['phone'] as String?;
            if (phone != null) {
              await prefs.setString(keyPhone, phone);
            }
          }
        } catch (e) {
          debugPrint("Error fetching emergency phone from Firestore: $e");
        }
      }
    }
    return phone;
  }

  Future<String?> getCurrentUserEmail() async {
    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        try {
          await user.reload();
          final updated = _firebaseAuth!.currentUser;
          if (updated != null && updated.emailVerified) {
            return updated.email;
          }
        } catch (_) {}
      }
      return null;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
      return isLoggedIn ? prefs.getString(keyEmail) : null;
    }
  }

  Future<bool> isEmailVerified() async {
    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        try {
          await user.reload();
          return _firebaseAuth!.currentUser?.emailVerified ?? false;
        } catch (_) {}
      }
      return false;
    }
    return true;
  }
}