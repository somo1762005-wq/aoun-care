import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/localization.dart';
import '../../../core/theme.dart';
import '../../../core/services/sms_service.dart'; // استيراد خدمة الـ SMS الجديدة
import '../../../data/repositories/auth_repository.dart'; // استيراد الـ Repository لجلب رقم الابن
import '../../../logic/medicine/medicine_cubit.dart';
import '../../../logic/language/language_cubit.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../widgets/theme_language_header.dart';
import '../auth_screen.dart';
import '../role_selection_screen.dart';

class FatherDashboard extends StatefulWidget {
  const FatherDashboard({super.key});

  @override
  State<FatherDashboard> createState() => _FatherDashboardState();
}

class _FatherDashboardState extends State<FatherDashboard> {
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationService();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationService() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        _uploadLocation(position);
      });
    } catch (e) {
      debugPrint("Error starting location tracking: $e");
    }
  }

  Future<void> _uploadLocation(Position position) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await fs.FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lastLocation': fs.GeoPoint(position.latitude, position.longitude),
          'lastLocationUpdate': fs.FieldValue.serverTimestamp(),
        }, fs.SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Failed to upload position: $e");
    }
  }

  String _formatDuration(Duration duration, String langCode) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (langCode == 'ar') {
      return '$minutes دقائق و $seconds ثواني';
    }

    return '$minutes min $seconds sec';
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<MedicineCubit, MedicineState>(
      builder: (context, state) {
        final hasNextDose = state.nextDoseMedicine != null && state.nextDoseCountdown != null;

        return Scaffold(
          appBar: ThemeLanguageHeader(
            titleKey: langCode == 'ar' ? 'واجهة الأب' : 'father_dashboard',
            extraActions: [
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
                  await context.read<AuthCubit>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                          (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person_rounded, color: Colors.white, size: 36),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    langCode == 'ar' ? 'مرحبًا بالوالد العزيز' : 'Welcome Dear Father',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    langCode == 'ar' ? 'أتمنى لك يومًا صحيًا' : 'Wishing you a healthy day',
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Countdown & SOS Button View
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 1. العداد الدائري الأصلي الخاص بك
                                Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 4),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 54),
                                      const SizedBox(height: 12),
                                      if (hasNextDose) ...[
                                        Text(
                                          AppLocalization.translate('next_dose_in', langCode),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          state.nextDoseMedicine!.name,
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDuration(state.nextDoseCountdown!, langCode),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                                          textAlign: TextAlign.center,
                                        ),
                                      ] else ...[
                                        Text(
                                          AppLocalization.translate('no_upcoming_doses', langCode),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // 2. زر الطوارئ الكبير والأحمر (SOS) مع توهج نبضي مريح للعين
                                GestureDetector(
                                  onTap: () async {
                                    final authRepo = context.read<AuthRepository>();
                                    String? sonPhone = await authRepo.getEmergencyPhone();

                                    if (sonPhone != null && sonPhone.isNotEmpty) {
                                      await SmsService.sendEmergencySms(
                                        phoneNumber: sonPhone,
                                        message: langCode == 'ar'
                                            ? "🚨 نداء استغاثة عاجل من الوالد! أنا أحتاج المساعدة فوراً، الرجاء القدوم أو الاتصال بي. 🚨"
                                            : "🚨 Urgent emergency appeal from Father! I need help immediately, please come or call me. 🚨",
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            langCode == 'ar'
                                                ? 'الرجاء إضافة رقم هاتف الابن في الإعدادات أولاً!'
                                                : 'Please add the son\'s phone number in settings first!',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 135,
                                    height: 135,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.shade700.withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.gpp_maybe_rounded, color: Colors.white, size: 40),
                                        const SizedBox(height: 4),
                                        Text(
                                          langCode == 'ar' ? "طوارئ\nSOS" : "EMERGENCY\nSOS",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Alarm Overlay
              if (state.isAlarmActive)
                Container(
                  color: Colors.black.withValues(alpha: 0.95),
                  width: double.infinity,
                  height: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_active, color: AppColors.error, size: 120),
                        const SizedBox(height: 32),
                        Text(
                          langCode == 'ar'
                              ? "الوالد العزيز حان موعد جرعتك\nاضغط هنا للتأكيد"
                              : AppLocalization.translate('time_to_take_medicine', langCode),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            state.activeAlarmMedicine?.name ?? "",
                            style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 36,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(height: 64),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.read<MedicineCubit>().confirmDoseTaken(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              elevation: 8,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            child: Text(
                              langCode == 'ar' ? "تم أخذ الجرعة" : "Dose Taken",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}