import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';
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

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadBuffers();
        // إعادة تهيئة الاستماع عند تغيير المستخدم لضمان جلب البيانات الجديدة
        _medicineRepository.refreshStreams();
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickCountdown();
    });
  }

  Future<void> _loadBuffers() async {
    final buffers = await _medicineRepository.getBuffers();
    emit(state.copyWith(
      fatherBufferMinutes: buffers['father'] ?? 30,
      sonBufferMinutes: buffers['son'] ?? 10,
    ));
  }

  Future<void> updateBuffers(int fatherMins, int sonMins) async {
    emit(state.copyWith(fatherBufferMinutes: fatherMins, sonBufferMinutes: sonMins));
    await _medicineRepository.saveBuffers(fatherMins, sonMins);
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

  void _triggerAlarm(Medicine medicine, String doseTimeLabel) {
    emit(state.copyWith(
      isAlarmActive: true,
      activeAlarmMedicine: medicine,
      activeAlarmTimeLabel: doseTimeLabel,
      isSonAlertActive: false,
      isSmsSent: false,
    ));
    _escalationFatherTimer?.cancel();
    _escalationFatherTimer = Timer(Duration(minutes: state.fatherBufferMinutes), () => _triggerEscalationToSon());
  }

  void _triggerEscalationToSon() {
    emit(state.copyWith(isSonAlertActive: true));
    _escalationSonTimer?.cancel();
    _escalationSonTimer = Timer(Duration(minutes: state.sonBufferMinutes), () => _sendBackgroundSms());
  }

  // 2. تفعيل الإرسال التلقائي الصامت (Background SMS)
  void _sendBackgroundSms() async {
    final phone = await _authRepository.getEmergencyPhone() ?? 'Unknown';
    final medName = state.activeAlarmMedicine?.name ?? 'Medicine';

    // نص رسالة صريح وبدون URL Encoding
    final smsBody = 'عاجل عوْن: الوالد لم يؤكد تناول جرعة دواء ($medName). يرجى الاطمئنان عليه فوراً.';

    debugPrint("---------------- BACKGROUND SMS ----------------");
    debugPrint("To: $phone");
    debugPrint("Message: $smsBody");
    debugPrint("Status: Initiating silent background send...");
    debugPrint("------------------------------------------------");

    if (!kIsWeb && Platform.isAndroid && phone != 'Unknown') {
      // طلب إذن الـ SMS أولاً
      if (await Permission.sms.request().isGranted) {
        SmsStatus status = await BackgroundSms.sendMessage(
          phoneNumber: phone,
          message: smsBody,
        );
        debugPrint("SMS Sent Status: $status");
      } else {
        debugPrint("SMS Permission Denied!");
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
      final updatedMedicine = medicine.copyWith(
        remainingQuantity: (medicine.remainingQuantity > 0) ? medicine.remainingQuantity - 1 : 0,
      );

      _medicineRepository.updateMedicine(updatedMedicine);
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
