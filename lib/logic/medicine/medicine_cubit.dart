import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/medicine.dart';
import '../../data/models/activity.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/auth_repository.dart';

class MedicineState {
  final List<Medicine> medicines;
  final List<ActivityLog> logs;
  final bool isLoading;
  final Medicine? nextDoseMedicine;
  final DateTime? nextDoseTime;
  final Duration? nextDoseCountdown;

  final bool isAlarmActive;
  final Medicine? activeAlarmMedicine;
  final String? activeAlarmTimeLabel;

  final bool isSonAlertActive;
  final bool isSmsSent;
  final List<String> smsLogs;

  final int fatherBufferMinutes;
  final int sonBufferMinutes;

  // إعدادات المنبه
  final double alarmVolume;
  final String alarmTone;
  final int snoozeMinutes;
  final bool isVibrationEnabled;

  final String? error;

  MedicineState({
    this.medicines = const [],
    this.logs = const [],
    this.isLoading = false,
    this.nextDoseMedicine,
    this.nextDoseTime,
    this.nextDoseCountdown,
    this.isAlarmActive = false,
    this.activeAlarmMedicine,
    this.activeAlarmTimeLabel,
    this.isSonAlertActive = false,
    this.isSmsSent = false,
    this.smsLogs = const [],
    this.fatherBufferMinutes = 30,
    this.sonBufferMinutes = 10,
    this.alarmVolume = 1.0,
    this.alarmTone = 'default',
    this.snoozeMinutes = 0,
    this.isVibrationEnabled = true,
    this.error,
  });

  MedicineState copyWith({
    List<Medicine>? medicines,
    List<ActivityLog>? logs,
    bool? isLoading,
    Medicine? nextDoseMedicine,
    DateTime? nextDoseTime,
    Duration? nextDoseCountdown,
    bool? isAlarmActive,
    Medicine? activeAlarmMedicine,
    String? activeAlarmTimeLabel,
    bool? isSonAlertActive,
    bool? isSmsSent,
    List<String>? smsLogs,
    int? fatherBufferMinutes,
    int? sonBufferMinutes,
    double? alarmVolume,
    String? alarmTone,
    int? snoozeMinutes,
    bool? isVibrationEnabled,
    String? error,
  }) {
    return MedicineState(
      medicines: medicines ?? this.medicines,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      nextDoseMedicine: nextDoseMedicine ?? this.nextDoseMedicine,
      nextDoseTime: nextDoseTime ?? this.nextDoseTime,
      nextDoseCountdown: nextDoseCountdown ?? this.nextDoseCountdown,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      activeAlarmMedicine: activeAlarmMedicine ?? this.activeAlarmMedicine,
      activeAlarmTimeLabel: activeAlarmTimeLabel ?? this.activeAlarmTimeLabel,
      isSonAlertActive: isSonAlertActive ?? this.isSonAlertActive,
      isSmsSent: isSmsSent ?? this.isSmsSent,
      smsLogs: smsLogs ?? this.smsLogs,
      fatherBufferMinutes: fatherBufferMinutes ?? this.fatherBufferMinutes,
      sonBufferMinutes: sonBufferMinutes ?? this.sonBufferMinutes,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      alarmTone: alarmTone ?? this.alarmTone,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      error: error ?? this.error,
    );
  }
}

class MedicineCubit extends Cubit<MedicineState> {
  final MedicineRepository _medicineRepository;
  final AuthRepository _authRepository;

  StreamSubscription? _medicineSubscription;
  StreamSubscription? _logsSubscription;
  StreamSubscription? _authSubscription;
  Timer? _countdownTimer;
  Timer? _escalationFatherTimer;
  Timer? _escalationSonTimer;

  MedicineCubit({
    required MedicineRepository medicineRepository,
    required AuthRepository authRepository,
  })  : _medicineRepository = medicineRepository,
        _authRepository = authRepository,
        super(MedicineState(isLoading: true)) {
    _startListening();
    _loadBuffers();
  }

  void _startListening() {
    _medicineSubscription = _medicineRepository.medicinesStream.listen((meds) {
      emit(state.copyWith(medicines: meds, isLoading: false));
      _recalculateNextDose();
    });

    _logsSubscription = _medicineRepository.logsStream.listen((activityLogs) {
      emit(state.copyWith(logs: activityLogs));
    });

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        // ننتظر قليلاً للتأكد من أن AuthRepository قد قام بمزامنة البيانات الأساسية
        await Future.delayed(const Duration(seconds: 1));
        await _loadBuffers();
        // إعادة تهيئة الاستماع عند تغيير المستخدم لضمان جلب البيانات الجديدة
        _medicineRepository.refreshStreams();
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickCountdown();
    });
  }

  Future<void> snoozeAlarm() async {
    _escalationFatherTimer?.cancel();
    _escalationSonTimer?.cancel();

    // يمكنك إضافة منطق إضافي هنا لتأجيل المنبه، مثل إعادة جدولة إشعار محلي
    // أو تحديث حالة الكيوبيت لتعكس أن المنبه في وضع التأجيل.
    // حالياً، سنقوم فقط بإلغاء المؤقتات وإعادة حساب الجرعة التالية.

    emit(state.copyWith(
      isAlarmActive: false,
      isSonAlertActive: false,
      isSmsSent: false,
      activeAlarmMedicine: null,
      activeAlarmTimeLabel: null,
    ));
    _recalculateNextDose();
  }

  Future<void> _loadBuffers() async {
    final buffers = await _medicineRepository.getBuffers();
    
    // تحميل الإعدادات مباشرة من SharedPreferences لضمان الاستقلالية
    final prefs = await SharedPreferences.getInstance();
    
    emit(state.copyWith(
      fatherBufferMinutes: buffers['father'] ?? 30,
      sonBufferMinutes: buffers['son'] ?? 10,
      alarmVolume: prefs.getDouble('alarm_volume') ?? 1.0,
      alarmTone: prefs.getString('alarm_tone') ?? 'default',
      snoozeMinutes: prefs.getInt('alarm_snooze') ?? 0,
      isVibrationEnabled: prefs.getBool('alarm_vibrate') ?? true,
    ));
  }

  Future<void> updateBuffers(int fatherMins, int sonMins) async {
    emit(state.copyWith(fatherBufferMinutes: fatherMins, sonBufferMinutes: sonMins));
    await _medicineRepository.saveBuffers(fatherMins, sonMins);
  }

  Future<void> updateAlarmSettings({
    double? volume,
    String? tone,
    int? snooze,
    bool? vibration,
  }) async {
    final newState = state.copyWith(
      alarmVolume: volume,
      alarmTone: tone,
      snoozeMinutes: snooze,
      isVibrationEnabled: vibration,
    );
    emit(newState);
    
    // حفظ الإعدادات مباشرة داخل الكيوبيت لضمان الاستقلالية
    final prefs = await SharedPreferences.getInstance();
    if (volume != null) await prefs.setDouble('alarm_volume', volume);
    if (tone != null) await prefs.setString('alarm_tone', tone);
    if (snooze != null) await prefs.setInt('alarm_snooze', snooze);
    if (vibration != null) await prefs.setBool('alarm_vibrate', vibration);
    
    // تمت إزالة استدعاء المستودع الخارجي لضمان استقلال الملف وعدم حدوث أخطاء بناء
  }

  void _recalculateNextDose() {
    if (state.medicines.isEmpty) {
      emit(state.copyWith(nextDoseMedicine: null, nextDoseTime: null, nextDoseCountdown: null));
      return;
    }

    final now = DateTime.now();
    DateTime? soonestTime;
    Medicine? soonestMedicine;

    for (final medicine in state.medicines) {
      if (!medicine.isScheduledForDate(now)) {
        bool foundNext = false;
        for (int i = 1; i <= 7; i++) {
          final nextDate = now.add(Duration(days: i));
          if (medicine.isScheduledForDate(nextDate)) {
            for (final timeStr in medicine.dosagesPerDay) {
              final parts = timeStr.split(':');
              final scheduleTime = DateTime(nextDate.year, nextDate.month, nextDate.day, int.parse(parts[0]), int.parse(parts[1]));
              if (soonestTime == null || scheduleTime.isBefore(soonestTime)) {
                soonestTime = scheduleTime;
                soonestMedicine = medicine;
                foundNext = true;
              }
            }
            if (foundNext) break;
          }
        }
        continue;
      }

      for (final timeStr in medicine.dosagesPerDay) {
        final parts = timeStr.split(':');
        DateTime scheduleTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));

        if (scheduleTime.isBefore(now)) {
          for (int i = 1; i <= 7; i++) {
            final nextDate = now.add(Duration(days: i));
            if (medicine.isScheduledForDate(nextDate)) {
              scheduleTime = DateTime(nextDate.year, nextDate.month, nextDate.day, int.parse(parts[0]), int.parse(parts[1]));
              break;
            }
          }
        }

        if (soonestTime == null || scheduleTime.isBefore(soonestTime)) {
          soonestTime = scheduleTime;
          soonestMedicine = medicine;
        }
      }
    }

    if (soonestTime != null) {
      emit(state.copyWith(
        nextDoseMedicine: soonestMedicine,
        nextDoseTime: soonestTime,
        nextDoseCountdown: soonestTime.difference(now),
      ));
    }
  }

  void _tickCountdown() {
    if (state.nextDoseTime == null) return;
    final now = DateTime.now();
    final difference = state.nextDoseTime!.difference(now);

    if (difference.isNegative || difference.inSeconds <= 0) {
      if (!state.isAlarmActive && state.nextDoseMedicine != null) {
        _triggerAlarm(state.nextDoseMedicine!, state.nextDoseMedicine!.dosagesPerDay.first);
      }
      _recalculateNextDose();
    } else {
      emit(state.copyWith(nextDoseCountdown: difference));
    }
  }

  void _triggerAlarm(Medicine medicine, String doseTimeLabel) async {
    emit(state.copyWith(
      isAlarmActive: true,
      activeAlarmMedicine: medicine,
      activeAlarmTimeLabel: doseTimeLabel,
      isSonAlertActive: false,
      isSmsSent: false,
    ));

    // إطلاق المنبه الصوتي مباشرة من داخل الكيوبيت لضمان الاستقلالية
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    String? soundResource = state.alarmTone == 'default' ? null : state.alarmTone;

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel_high_priority',
      'المنبهات الصوتية لعون',
      channelDescription: 'قناة إنذار صوتي مخصصة وقابلة للتعديل',
      importance: Importance.max,
      priority: Priority.high,
      sound: soundResource != null ? RawResourceAndroidNotificationSound(soundResource) : null,
      playSound: true,
      enableVibration: state.isVibrationEnabled,
      vibrationPattern: state.isVibrationEnabled ? Int64List.fromList([0, 1000, 500, 1000]) : null,
      ongoing: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      'تنبيه موعد دواء',
      'حان الآن موعد جرعة: ${medicine.name}',
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
    );

    _escalationFatherTimer?.cancel();
    _escalationFatherTimer = Timer(Duration(minutes: state.fatherBufferMinutes), () => _triggerEscalationToSon());
  }

  void _triggerEscalationToSon() {
    emit(state.copyWith(isSonAlertActive: true));
    _escalationSonTimer?.cancel();
    _escalationSonTimer = Timer(Duration(minutes: state.sonBufferMinutes), () => _sendBackgroundSms());
  }

  static const _smsChannel = MethodChannel('com.aoun.app/sms');

  // 2. تفعيل الإرسال التلقائي الصامت (Native Background SMS via MethodChannel)
  void _sendBackgroundSms() async {
    final phoneNumber = await _authRepository.getEmergencyPhone() ?? 'Unknown';

    debugPrint("---------------- NATIVE BACKGROUND SMS ----------------");
    debugPrint("To: $phoneNumber");
    debugPrint("Status: Initiating native silent send via MethodChannel...");
    debugPrint("-------------------------------------------------------");

    if (!kIsWeb && Platform.isAndroid && phoneNumber != 'Unknown') {
      try {
        // طلب إذن الـ SMS أولاً عبر permission_handler
        if (await Permission.sms.request().isGranted) {
          const platform = MethodChannel('com.aoun.app/sms');
          await platform.invokeMethod('sendSMS', {
            'phone': phoneNumber,
            'message': 'تحذير من تطبيق عوْن: كبير السن لم يقم بتأكيد أخذ جرعة الدواء في الوقت المحدد.'
          });
          debugPrint("تم إرسال الـ SMS بنجاح في الخلفية عبر الـ Native Channel");
        } else {
          debugPrint("SMS Permission Denied!");
        }
      } catch (e) {
        debugPrint("خطأ أثناء استدعاء ميثود الـ SMS: $e");
      }
    }

    emit(state.copyWith(isSmsSent: true));
    if (state.activeAlarmMedicine != null) {
      await _medicineRepository.addActivityLog(ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineName: state.activeAlarmMedicine!.name,
        timestamp: DateTime.now(),
        takenByFather: false,
        timeLabel: state.activeAlarmTimeLabel ?? 'Auto',
      ));
    }
  }

  Future<void> confirmDoseTaken() async {
    _escalationFatherTimer?.cancel();
    _escalationSonTimer?.cancel();

    final medicine = state.activeAlarmMedicine;

    emit(state.copyWith(
      isAlarmActive: false,
      isSonAlertActive: false,
      isSmsSent: false,
      activeAlarmMedicine: null,
      activeAlarmTimeLabel: null,
    ));

    if (medicine != null) {
      // 3. إنقاص الكمية المتبقية بمقدار 1 وتحديث Firestore
      final updatedMedicine = medicine.copyWith(
        remainingQuantity: (medicine.remainingQuantity > 0) ? medicine.remainingQuantity - 1 : 0,
      );

      _medicineRepository.updateMedicine(updatedMedicine);

      // تنبيه نفاذ الكمية (سيظهر في الواجهة بناءً على القيمة المحدثة)
      if (updatedMedicine.remainingQuantity <= 2) {
        debugPrint("ALERT: ${updatedMedicine.name} is running low!");
      }
      _medicineRepository.addActivityLog(ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineName: medicine.name,
        timestamp: DateTime.now(),
        takenByFather: true,
        timeLabel: state.activeAlarmTimeLabel ?? 'Manual',
      ));
    }

    _recalculateNextDose();
  }

  void caregiverAcknowledge() {
    _escalationSonTimer?.cancel();
    emit(state.copyWith(isSonAlertActive: false));
  }

  Future<void> addMed(Medicine medicine) async => await _medicineRepository.addMedicine(medicine);
  Future<void> editMed(Medicine medicine) async => await _medicineRepository.updateMedicine(medicine);
  Future<void> deleteMed(String id) async => await _medicineRepository.deleteMedicine(id);

  @override
  Future<void> close() {
    _medicineSubscription?.cancel();
    _logsSubscription?.cancel();
    _authSubscription?.cancel();
    _countdownTimer?.cancel();
    _escalationFatherTimer?.cancel();
    _escalationSonTimer?.cancel();
    return super.close();
  }
}
