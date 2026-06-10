import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../models/activity.dart';
import 'auth_repository.dart';

class MedicineRepository {
  // التعديل السحري: منع استدعاء الفايرستور مباشرة عند التشغيل لتفادي الشاشة السوداء
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

  // Exposed getters for verification
  bool get isFirebaseEnabled => _isFirebaseEnabled;
  fs.FirebaseFirestore? get firestore => _firestore;

  static const String keyMedicinesJson = 'cached_medicines';
  static const String keyLogsJson = 'cached_logs';
  static const String keyFatherBuffer = 'father_buffer_minutes';
  static const String keySonBuffer = 'son_buffer_minutes';

  // Streams for live UI updates
  final _medicinesController = StreamController<List<Medicine>>.broadcast();
  final _logsController = StreamController<List<ActivityLog>>.broadcast();

  Stream<List<Medicine>> get medicinesStream => _medicinesController.stream;
  Stream<List<ActivityLog>> get logsStream => _logsController.stream;

  List<Medicine> _localMedicines = [];
  List<ActivityLog> _localLogs = [];

  StreamSubscription? _firestoreMedsSub;
  StreamSubscription? _firestoreLogsSub;

  MedicineRepository(AuthRepository authRepository) {
    if (_isFirebaseEnabled) {
      authRepository.authStateChanges.listen((email) {
        if (email != null) {
          _startFirestoreSync();
        } else {
          _stopFirestoreSync();
          _loadLocalDataFallback();
        }
      });
    } else {
      _loadLocalDataFallback();
    }
  }

  bool get _isFirebaseEnabled {
    try {
      return fs.FirebaseFirestore.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _startFirestoreSync() {
    _stopFirestoreSync();

    try {
      if (_isFirebaseEnabled && _firestore != null) {
        debugPrint("Starting real-time Firestore sync in MedicineRepository...");

        _firestoreMedsSub = _firestore!.collection('medicines').snapshots().listen((snapshot) {
          final medicines = snapshot.docs.map((doc) {
            return Medicine.fromMap(doc.data(), doc.id);
          }).toList();
          _medicinesController.add(medicines);
        }, onError: (err) {
          debugPrint("Firestore medicines stream error: $err");
          _loadLocalDataFallback();
        });

        _firestoreLogsSub = _firestore!.collection('activities').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
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
    debugPrint("Stopped Firestore sync in MedicineRepository.");
  }

  // دالة منفصلة لتحميل البيانات المحلية بأمان
  Future<void> _loadLocalDataFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final medsRaw = prefs.getString(keyMedicinesJson);
    final logsRaw = prefs.getString(keyLogsJson);

    if (medsRaw != null) {
      final List decoded = jsonDecode(medsRaw);
      _localMedicines = decoded.map((m) => Medicine.fromMap(m['data'], m['id'])).toList();
    } else {
      // Seed default dummy data for rich design aesthetics
      _localMedicines = [
        Medicine(
          id: 'med1',
          name: 'بنادول - Panadol',
          dosagesPerDay: ['08:00', '14:00', '22:00'],
          remainingQuantity: 12,
          initialQuantity: 30,
          thresholdQuantity: 3,
        ),
        Medicine(
          id: 'med2',
          name: 'أسبيرين - Aspirin',
          dosagesPerDay: ['09:00'],
          remainingQuantity: 2,
          initialQuantity: 10,
          thresholdQuantity: 3,
        )
      ];
      await _saveLocalMedicines();
    }

    if (logsRaw != null) {
      final List decoded = jsonDecode(logsRaw);
      _localLogs = decoded.map((l) => ActivityLog.fromMap(l['data'], l['id'])).toList();
    } else {
      _localLogs = [
        ActivityLog(
          id: 'log1',
          medicineName: 'بنادول - Panadol',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          takenByFather: true,
          timeLabel: '08:00',
        )
      ];
      await _saveLocalLogs();
    }

    _medicinesController.add(_localMedicines);
    _logsController.add(_localLogs);
  }

  Future<void> _saveLocalMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _localMedicines.map((m) => {
      'id': m.id,
      'data': m.toMap(),
    }).toList();
    await prefs.setString(keyMedicinesJson, jsonEncode(list));
    _medicinesController.add(_localMedicines);
  }

  Future<void> _saveLocalLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _localLogs.map((l) => {
      'id': l.id,
      'data': l.toMap(),
    }).toList();
    await prefs.setString(keyLogsJson, jsonEncode(list));
    _logsController.add(_localLogs);
  }

  // CRUD Operations
  Future<void> addMedicine(Medicine medicine) async {
    if (_isFirebaseEnabled && _firestore != null) {
      await _firestore!.collection('medicines').add(medicine.toMap());
    } else {
      _localMedicines.add(medicine);
      await _saveLocalMedicines();
    }
  }

  Future<void> updateMedicine(Medicine medicine) async {
    if (_isFirebaseEnabled && _firestore != null) {
      await _firestore!.collection('medicines').doc(medicine.id).update(medicine.toMap());
    } else {
      final index = _localMedicines.indexWhere((m) => m.id == medicine.id);
      if (index != -1) {
        _localMedicines[index] = medicine;
        await _saveLocalMedicines();
      }
    }
  }

  Future<void> deleteMedicine(String id) async {
    if (_isFirebaseEnabled && _firestore != null) {
      await _firestore!.collection('medicines').doc(id).delete();
    } else {
      _localMedicines.removeWhere((m) => m.id == id);
      await _saveLocalMedicines();
    }
  }

  // Log Operations
  Future<void> addActivityLog(ActivityLog log) async {
    if (_isFirebaseEnabled && _firestore != null) {
      await _firestore!.collection('activities').add(log.toMap());
    } else {
      _localLogs.insert(0, log);
      await _saveLocalLogs();
    }
  }

  // Escalation Setting Configurations
  Future<void> saveBuffers(int fatherMins, int sonMins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyFatherBuffer, fatherMins);
    await prefs.setInt(keySonBuffer, sonMins);
    if (_isFirebaseEnabled && _firestore != null) {
      await _firestore!.collection('settings').doc('buffers').set({
        'father_buffer': fatherMins,
        'son_buffer': sonMins,
      });
    }
  }

  Future<Map<String, int>> getBuffers() async {
    final prefs = await SharedPreferences.getInstance();
    int fatherMins = prefs.getInt(keyFatherBuffer) ?? 30;
    int sonMins = prefs.getInt(keySonBuffer) ?? 10;
    return {
      'father': fatherMins,
      'son': sonMins,
    };
  }
}