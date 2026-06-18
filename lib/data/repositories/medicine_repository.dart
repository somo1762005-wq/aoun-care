import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../models/activity.dart';
import 'auth_repository.dart';

class MedicineRepository {
  fs.FirebaseFirestore? get _firestore {
    if (_isFirebaseEnabled) {
      try {
        return fs.FirebaseFirestore.instance;
      } catch (e) {
        debugPrint("Error accessing FirebaseFirestore instance: $e");
        return null;
      }
    }
    return null;
  }

  static const String keyMedicinesJson = 'cached_medicines';
  static const String keyLogsJson = 'cached_logs';
  static const String keyCareRecipientBuffer = 'care_recipient_buffer_minutes';
  static const String keyCaregiverBuffer = 'caregiver_buffer_minutes';
  static const String keyAlarmVolume = 'alarm_volume';
  static const String keyAlarmTone = 'alarm_tone';
  static const String keyAlarmSnooze = 'alarm_snooze';
  static const String keyAlarmVibration = 'alarm_vibration';

  final _medicinesController = StreamController<List<Medicine>>.broadcast();
  final _logsController = StreamController<List<ActivityLog>>.broadcast();

  Stream<List<Medicine>> get medicinesStream => _medicinesController.stream;
  Stream<List<ActivityLog>> get logsStream => _logsController.stream;

  List<Medicine> _localMedicines = [];
  List<ActivityLog> _localLogs = [];

  StreamSubscription? _firestoreMedsSub;
  StreamSubscription? _firestoreLogsSub;

  MedicineRepository(AuthRepository authRepository) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint("MedicineRepository: User logged in, starting sync for ${user.uid}");
        _startFirestoreSync(user.uid);
      } else {
        debugPrint("MedicineRepository: User logged out, stopping sync");
        _stopFirestoreSync();
        _loadLocalDataFallback();
      }
    });
    // فحص أولي في حالة كان المستخدم مسجلاً للدخول بالفعل عند إنشاء الـ Repository
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _startFirestoreSync(currentUser.uid);
    }
  }

  bool get _isFirebaseEnabled {
    try {
      return fs.FirebaseFirestore.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void refreshStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _startFirestoreSync(user.uid);
    }
  }

  void _startFirestoreSync(String userId) {
    _stopFirestoreSync();

    try {
      if (_isFirebaseEnabled && _firestore != null) {
        debugPrint("Starting real-time Firestore sync for user: $userId");

        _firestoreMedsSub = _firestore!
            .collection('users')
            .doc(userId)
            .collection('medicines')
            .snapshots()
            .listen((snapshot) {
          final medicines = snapshot.docs.map((doc) {
            return Medicine.fromMap(doc.data(), doc.id);
          }).toList();
          _medicinesController.add(medicines);
        }, onError: (err) {
          debugPrint("Firestore medicines stream error: $err");
          _loadLocalDataFallback();
        });

        _firestoreLogsSub = _firestore!
            .collection('users')
            .doc(userId)
            .collection('activities')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          final logs = snapshot.docs.map((doc) {
            return ActivityLog.fromMap(doc.data(), doc.id);
          }).toList();
          _logsController.add(logs);
        }, onError: (err) {
          debugPrint("Firestore activities stream error: $err");
        });
      } else {
        _loadLocalDataFallback();
      }
    } catch (e) {
      debugPrint("Error starting Firestore sync: $e");
      _loadLocalDataFallback();
    }
  }

  void _stopFirestoreSync() {
    _firestoreMedsSub?.cancel();
    _firestoreLogsSub?.cancel();
    _firestoreMedsSub = null;
    _firestoreLogsSub = null;
  }

  Future<void> _loadLocalDataFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final medsRaw = prefs.getString(keyMedicinesJson);
    final logsRaw = prefs.getString(keyLogsJson);

    if (medsRaw != null) {
      final List decoded = jsonDecode(medsRaw);
      _localMedicines = decoded.map((m) => Medicine.fromMap(m['data'], m['id'])).toList();
    } else {
      _localMedicines = [];
    }

    if (logsRaw != null) {
      final List decoded = jsonDecode(logsRaw);
      _localLogs = decoded.map((l) => ActivityLog.fromMap(l['data'], l['id'])).toList();
    } else {
      _localLogs = [];
    }

    _medicinesController.add(_localMedicines);
    _logsController.add(_localLogs);
  }

  Future<void> addMedicine(Medicine medicine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_isFirebaseEnabled && _firestore != null && user != null) {
      final medData = medicine.toMap();
      await _firestore!.collection('users').doc(user.uid).collection('medicines').add(medData);
    } else {
      _localMedicines.add(medicine);
      _medicinesController.add(_localMedicines);
    }
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_isFirebaseEnabled && _firestore != null && user != null) {
      final medData = medicine.toMap();
      await _firestore!.collection('users').doc(user.uid).collection('medicines').doc(medicine.id).update(medData);
    } else {
      final index = _localMedicines.indexWhere((m) => m.id == medicine.id);
      if (index != -1) {
        _localMedicines[index] = medicine;
        _medicinesController.add(_localMedicines);
      }
    }
  }

  Future<void> deleteMedicine(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_isFirebaseEnabled && _firestore != null && user != null) {
      await _firestore!.collection('users').doc(user.uid).collection('medicines').doc(id).delete();
    } else {
      _localMedicines.removeWhere((m) => m.id == id);
      _medicinesController.add(_localMedicines);
    }
  }

  Future<void> addActivityLog(ActivityLog log) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_isFirebaseEnabled && _firestore != null && user != null) {
      final logData = log.toMap();
      await _firestore!.collection('users').doc(user.uid).collection('activities').add(logData);
    } else {
      _localLogs.insert(0, log);
      _logsController.add(_localLogs);
    }
  }

  Future<void> saveBuffers(int careRecipientMins, int caregiverMins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyCareRecipientBuffer, careRecipientMins);
    await prefs.setInt(keyCaregiverBuffer, caregiverMins);

    final user = FirebaseAuth.instance.currentUser;
    if (_isFirebaseEnabled && _firestore != null && user != null) {
      await _firestore!.collection('users').doc(user.uid).set({
        'care_recipient_buffer': careRecipientMins,
        'caregiver_buffer': caregiverMins,
      }, fs.SetOptions(merge: true));
    }
  }

  Future<Map<String, int>> getBuffers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_isFirebaseEnabled && _firestore != null && user != null) {
      try {
        final doc = await _firestore!.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && (data.containsKey('care_recipient_buffer') || data.containsKey('father_buffer'))) {
            final f = data['care_recipient_buffer'] ?? data['father_buffer'] as int;
            final s = data['caregiver_buffer'] ?? data['son_buffer'] as int;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(keyCareRecipientBuffer, f);
            await prefs.setInt(keyCaregiverBuffer, s);
            return {'father': f, 'son': s};
          }
        }
      } catch (e) {
        debugPrint("Error fetching buffers from Firestore: $e");
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return {
      'father': prefs.getInt(keyCareRecipientBuffer) ?? 30,
      'son': prefs.getInt(keyCaregiverBuffer) ?? 10,
    };
  }

  Future<void> saveAlarmSettings({
    required double volume,
    required String tone,
    required int snooze,
    required bool vibration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyAlarmVolume, volume);
    await prefs.setString(keyAlarmTone, tone);
    await prefs.setInt(keyAlarmSnooze, snooze);
    await prefs.setBool(keyAlarmVibration, vibration);

    final user = FirebaseAuth.instance.currentUser;
    if (_isFirebaseEnabled && _firestore != null && user != null) {
      await _firestore!.collection('users').doc(user.uid).set({
        'alarm_settings': {
          'volume': volume,
          'tone': tone,
          'snooze': snooze,
          'vibration': vibration,
        }
      }, fs.SetOptions(merge: true));
    }
  }

  Future<Map<String, dynamic>> getAlarmSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_isFirebaseEnabled && _firestore != null && user != null) {
      try {
        final doc = await _firestore!.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data.containsKey('alarm_settings')) {
            final settings = data['alarm_settings'] as Map<String, dynamic>;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble(keyAlarmVolume, (settings['volume'] as num).toDouble());
            await prefs.setString(keyAlarmTone, settings['tone'] as String);
            await prefs.setInt(keyAlarmSnooze, settings['snooze'] as int);
            await prefs.setBool(keyAlarmVibration, settings['vibration'] as bool);
            return settings;
          }
        }
      } catch (e) {
        debugPrint("Error fetching alarm settings from Firestore: $e");
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return {
      'volume': prefs.getDouble(keyAlarmVolume) ?? 1.0,
      'tone': prefs.getString(keyAlarmTone) ?? 'default',
      'snooze': prefs.getInt(keyAlarmSnooze) ?? 0,
      'vibration': prefs.getBool(keyAlarmVibration) ?? true,
    };
  }
}
