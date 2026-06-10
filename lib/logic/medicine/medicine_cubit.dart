import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Alarm states (Father side)
  final bool isAlarmActive;
  final Medicine? activeAlarmMedicine;
  final String? activeAlarmTimeLabel;

  // Escalation alert states (Son side)
  final bool isSonAlertActive;
  final bool isSmsSent;
  final List<String> smsLogs;

  // Configuration buffers
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
    _triggerImmediateMockFetch();
  }

  void _startListening() {
    _medicineSubscription = _medicineRepository.medicinesStream.listen((meds) {
      emit(state.copyWith(medicines: meds, isLoading: false));
      _recalculateNextDose();
    });

    _logsSubscription = _medicineRepository.logsStream.listen((activityLogs) {
      emit(state.copyWith(logs: activityLogs));
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickCountdown();
    });
  }

  void _triggerImmediateMockFetch() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (state.isLoading) {
        emit(state.copyWith(isLoading: false));
      }
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
    await _medicineRepository.saveBuffers(fatherMins, sonMins);
    emit(state.copyWith(
      fatherBufferMinutes: fatherMins,
      sonBufferMinutes: sonMins,
    ));
  }

  void _recalculateNextDose() {
    if (state.medicines.isEmpty) {
      emit(state.copyWith(
        nextDoseMedicine: null,
        nextDoseTime: null,
        nextDoseCountdown: null,
      ));
      return;
    }

    final now = DateTime.now();
    DateTime? soonestTime;
    Medicine? soonestMedicine;

    for (final medicine in state.medicines) {
      for (final timeStr in medicine.dosagesPerDay) {
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;

        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        DateTime scheduleTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        if (scheduleTime.isBefore(now)) {
          scheduleTime = scheduleTime.add(const Duration(days: 1));
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

    _escalationFatherTimer = Timer(Duration(minutes: state.fatherBufferMinutes), () {
      _triggerEscalationToSon();
    });
  }

  void demoTriggerAlarm(String medName) {
    final med = state.medicines.firstWhere(
          (m) => m.name.contains(medName),
      orElse: () => Medicine(
        id: 'demo_id',
        name: medName,
        dosagesPerDay: ['الآن'],
        remainingQuantity: 10,
        initialQuantity: 20,
      ),
    );
    _triggerAlarm(med, 'الآن');
  }

  void _triggerEscalationToSon() {
    emit(state.copyWith(
      isSonAlertActive: true,
    ));

    _escalationSonTimer?.cancel();

    _escalationSonTimer = Timer(Duration(minutes: state.sonBufferMinutes), () {
      _sendSimulatedSms();
    });
  }

  void _sendSimulatedSms() async {
    final phone = await _authRepository.getEmergencyPhone() ?? 'رقم غير معروف';
    final medName = state.activeAlarmMedicine?.name ?? 'الدواء';
    final smsBody = '‼️ عاجل عوْن: الأب لم يؤكد تناول جرعة دواء ($medName) في موعدها المتوقع. يرجى الاطمئنان عليه فوراً!';

    bool realSent = false;

    // استخدام url_launcher لفتح واجهة الـ SMS الرسمية والمستقرة
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && phone != 'رقم غير معروف') {
      try {
        final Uri smsLaunchUri = Uri(
          scheme: 'sms',
          path: phone,
          queryParameters: <String, String>{
            'body': smsBody,
          },
        );

        if (await canLaunchUrl(smsLaunchUri)) {
          await launchUrl(smsLaunchUri);
          realSent = true;
          debugPrint("SMS interface launched successfully to $phone.");
        } else {
          debugPrint("Could not launch SMS URL client.");
        }
      } catch (e) {
        debugPrint("Error launching SMS via url_launcher: $e");
      }
    }

    final logPrefix = realSent ? 'تم فتح واجهة الإرسال إلى' : 'محاكاة الإرسال إلى';
    final logMessage = '$logPrefix $phone: "$smsBody"';
    final updatedLogs = List<String>.from(state.smsLogs)..add(logMessage);

    emit(state.copyWith(
      isSmsSent: true,
      smsLogs: updatedLogs,
    ));

    if (state.activeAlarmMedicine != null) {
      await _medicineRepository.addActivityLog(
        ActivityLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          medicineName: state.activeAlarmMedicine!.name,
          timestamp: DateTime.now(),
          takenByFather: false,
          timeLabel: state.activeAlarmTimeLabel ?? '',
        ),
      );
    }
  }

  Future<void> confirmDoseTaken() async {
    _escalationFatherTimer?.cancel();
    _escalationSonTimer?.cancel();

    final medicine = state.activeAlarmMedicine;
    if (medicine != null) {
      final updatedMedicine = medicine.copyWith(
        remainingQuantity: (medicine.remainingQuantity > 0)
            ? medicine.remainingQuantity - 1
            : 0,
      );
      await _medicineRepository.updateMedicine(updatedMedicine);

      await _medicineRepository.addActivityLog(
        ActivityLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          medicineName: medicine.name,
          timestamp: DateTime.now(),
          takenByFather: true,
          timeLabel: state.activeAlarmTimeLabel ?? 'غير محدد',
        ),
      );
    }

    emit(state.copyWith(
      isAlarmActive: false,
      activeAlarmMedicine: null,
      activeAlarmTimeLabel: null,
      isSonAlertActive: false,
      isSmsSent: false,
    ));

    _recalculateNextDose();
  }

  void caregiverAcknowledge() {
    _escalationSonTimer?.cancel();
    emit(state.copyWith(
      isSonAlertActive: false,
    ));
  }

  void setMedicines(List<Medicine> meds) {
    emit(state.copyWith(medicines: meds));
    _recalculateNextDose();
  }

  Future<void> addMed(Medicine medicine) async {
    await _medicineRepository.addMedicine(medicine);
  }

  Future<void> editMed(Medicine medicine) async {
    await _medicineRepository.updateMedicine(medicine);
  }

  Future<void> deleteMed(String id) async {
    await _medicineRepository.deleteMedicine(id);
  }

  @override
  Future<void> close() {
    _medicineSubscription?.cancel();
    _logsSubscription?.cancel();
    _countdownTimer?.cancel();
    _escalationFatherTimer?.cancel();
    _escalationSonTimer?.cancel();
    return super.close();
  }
}