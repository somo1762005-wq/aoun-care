import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../logic/medicine/medicine_cubit.dart';
import '../../../core/services/sms_service.dart'; // استيراد خدمة الـ SMS
import '../../../data/repositories/auth_repository.dart'; // استيراد الـ Repository لجلب رقم الابن

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  Timer? _safetyTimer;
  bool _isActionTaken = false;
  int _delayMinutes = 10; // القيمة الافتراضية (مثلاً 10 دقائق) في حال فشل الجلب من الإعدادات

  @override
  void initState() {
    super.initState();
    _fetchDelayAndStartTimer();
  }

  /// جلب المهلة الديناميكية التي حددها الابن في الإعدادات من الـ Firestore
  Future<void> _fetchDelayAndStartTimer() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['safety_delay_minutes'] != null) {
          setState(() {
            // قم بتغيير 'safety_delay_minutes' إلى الحقل الحقيقي الذي يحفظ فيه الابن المهلة
            _delayMinutes = doc.data()?['safety_delay_minutes'] as int;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching dynamic safety delay: $e");
    }
    _startSafetyCountdown();
  }

  /// بدء العد التنازلي بناءً على المهلة المستلمة
  void _startSafetyCountdown() {
    _safetyTimer = Timer(Duration(minutes: _delayMinutes), () async {
      final medicineState = context.read<MedicineCubit>().state;
      final medicine = medicineState.activeAlarmMedicine;

      // إذا لم يضغط الوالد على أي زر، والمنبه ما زال نشطاً
      if (!_isActionTaken && medicine != null) {
        final authRepo = context.read<AuthRepository>();
        String? sonPhone = await authRepo.getEmergencyPhone();

        if (sonPhone != null && sonPhone.isNotEmpty) {
          await SmsService.sendEmergencySms(
            phoneNumber: sonPhone,
            message: "⚠️ تنبيه أمان من تطبيق عون: مرت ($_delayMinutes) دقائق ولم يقم الوالد بتأكيد أخذ جرعة دواء (${medicine.name}). الرجاء الاطمئنان عليه فوراً.",
          );
        }
      }
    });
  }

  /// إيقاف المؤقت فوراً عند استجابة الوالد
  void _cancelTimer() {
    setState(() {
      _isActionTaken = true;
    });
    _safetyTimer?.cancel();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel(); // تنظيف الذاكرة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicineCubit, MedicineState>(
      builder: (context, state) {
        final medicine = state.activeAlarmMedicine;
        if (medicine == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        const themeColor = Colors.redAccent;

        return Scaffold(
          backgroundColor: themeColor,
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.notifications_active,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                const Text(
                  'حان موعد دواء',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  medicine.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'الجرعة: ${state.activeAlarmTimeLabel ?? "الحالية"}',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _cancelTimer(); // إلغاء الـ SMS التلقائي فوراً
                          context.read<MedicineCubit>().confirmDoseTaken();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: themeColor,
                          minimumSize: const Size(double.infinity, 80),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'تأكيد أخذ الجرعة',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          _cancelTimer(); // إلغاء الـ SMS التلقائي لأن الوالد أجل المنبه بوعيه
                          context.read<MedicineCubit>().caregiverAcknowledge();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                        ),
                        child: const Text(
                          'تأجيل المنبه (Snooze)',
                          style: TextStyle(fontSize: 20, decoration: TextDecoration.underline),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}