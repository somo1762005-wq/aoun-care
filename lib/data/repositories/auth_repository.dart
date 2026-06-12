import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/notification_service.dart';

class AuthRepository {
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

  static const String keyRole = 'user_role';
  static const String keyEmail = 'user_email';
  static const String keyPhone = 'son_phone';
  static const String keyIsLoggedIn = 'is_logged_in';

  final _authStateController = StreamController<String?>.broadcast();
  Stream<String?> get authStateChanges => _authStateController.stream;

  AuthRepository() {
    _init();
  }

  bool get _isFirebaseEnabled {
    try {
      return fb.FirebaseAuth.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _init() async {
    try {
      if (_isFirebaseEnabled && _firebaseAuth != null) {
        _firebaseAuth!.authStateChanges().listen((user) async {
          if (user != null) {
            // جلب البيانات فوراً عند كشف المستخدم
            await _syncUserData(user);
            _authStateController.add(user.email);
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

  Future<void> _syncUserData(fb.User user) async {
    try {
      final doc = await _firestore?.collection('users').doc(user.uid).get();
      if (doc != null && doc.exists) {
        final data = doc.data();
        final prefs = await SharedPreferences.getInstance();

        if (data != null) {
          if (data['role'] != null) await prefs.setString(keyRole, data['role']);
          if (data['phone'] != null) await prefs.setString(keyPhone, data['phone']);
          await prefs.setString(keyEmail, user.email ?? '');
          await prefs.setBool(keyIsLoggedIn, true);
        }
      }
    } catch (e) {
      debugPrint("Error syncing user data from Firestore: $e");
    }
  }

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
      if (credential.user != null) {
        await _syncUserData(credential.user!);
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
        await _firestore?.collection('users').doc(user.uid).set({
          'email': email,
          'phone': phone,
          'createdAt': fs.FieldValue.serverTimestamp(),
          'role': 'none',
        });
        await _syncUserData(user);
      }
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
    await prefs.remove(keyEmail);

    if (_isFirebaseEnabled && _firebaseAuth != null) {
      await _firebaseAuth!.signOut();
    } else {
      _authStateController.add(null);
    }
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyRole, role);

    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        await _firestore?.collection('users').doc(user.uid).set({
          'role': role,
        }, fs.SetOptions(merge: true));
      }
    }
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final localRole = prefs.getString(keyRole);

    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        try {
          final doc = await _firestore?.collection('users').doc(user.uid).get();
          if (doc != null && doc.exists) {
            final role = doc.data()?['role'] as String?;
            if (role != null) {
              await prefs.setString(keyRole, role);
              return role;
            }
          }
        } catch (e) {
          debugPrint("Error fetching role from Firestore: $e");
        }
      }
    }
    return localRole;
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
    final localPhone = prefs.getString(keyPhone);

    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        try {
          final doc = await _firestore?.collection('users').doc(user.uid).get();
          if (doc != null && doc.exists) {
            final phone = doc.data()?['phone'] as String?;
            if (phone != null) {
              await prefs.setString(keyPhone, phone);
              return phone;
            }
          }
        } catch (e) {
          debugPrint("Error fetching emergency phone from Firestore: $e");
        }
      }
    }
    return localPhone;
  }

  Future<String?> getCurrentUserEmail() async {
    if (_isFirebaseEnabled && _firebaseAuth != null) {
      final user = _firebaseAuth!.currentUser;
      return user?.email;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
      return isLoggedIn ? prefs.getString(keyEmail) : null;
    }
  }

  String? get currentUserId {
    return _firebaseAuth?.currentUser?.uid;
  }

  Future<bool> isEmailVerified() async {
    return true;
  }
}
