import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs; // Wait, we should use package:cloud_firestore/cloud_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../../../core/localization.dart';
import '../../../core/theme.dart';
import '../../../data/models/medicine.dart';
import '../../../logic/medicine/medicine_cubit.dart';
import '../../../logic/language/language_cubit.dart';
import '../../widgets/theme_language_header.dart';
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
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied.");
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission permanently denied.");
        return;
      }

      // Start listening to the stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen((Position position) {
        _uploadLocation(position);
      }, onError: (err) {
        debugPrint("Geolocator stream error: $err");
      });
    } catch (e) {
      debugPrint("Error starting location tracking: $e");
    }
  }

  Future<void> _uploadLocation(Position position) async {
    try {
      final firestore = fs.FirebaseFirestore.instance;
      if (firestore.app.name.isNotEmpty) {
        await firestore.collection('locations').doc('father').set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': fs.FieldValue.serverTimestamp(),
        });
        debugPrint("Uploaded father position: ${position.latitude}, ${position.longitude}");
      }
    } catch (e) {
      debugPrint("Failed to upload position: $e");
    }
  }

  Stream<List<Medicine>> _getMedicinesStream() {
    try {
      final firestore = fs.FirebaseFirestore.instance;
      if (firestore.app.name.isNotEmpty) {
        return firestore.collection('medicines').snapshots().map((snapshot) {
          return snapshot.docs.map((doc) {
            return Medicine.fromMap(doc.data(), doc.id);
          }).toList();
        });
      }
    } catch (_) {}
    return const Stream.empty();
  }

  String _formatDuration(Duration duration, String langCode) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // If exactly 5 minutes, display the specific Arabic string requested: "متبقي على الجرعة القادمة خمس دقائق"
    if (langCode == 'ar' && duration.inMinutes == 5 && seconds == 0) {
      return 'خمس دقائق';
    }

    String formatted = '';
    if (hours > 0) {
      formatted += '$hours ${langCode == 'ar' ? 'ساعة' : 'hr'} ';
    }
    formatted += '$minutes ${AppLocalization.translate('minutes', langCode)} ';
    formatted += '$seconds ${AppLocalization.translate('seconds', langCode)}';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Medicine>>(
      stream: _getMedicinesStream(),
      builder: (context, firestoreSnapshot) {
        if (firestoreSnapshot.hasData && firestoreSnapshot.data != null) {
          final meds = firestoreSnapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<MedicineCubit>().setMedicines(meds);
            }
          });
        }

        return BlocBuilder<MedicineCubit, MedicineState>(
          builder: (context, state) {
            final hasNextDose = state.nextDoseMedicine != null && state.nextDoseCountdown != null;

            return Scaffold(
              appBar: ThemeLanguageHeader(
                titleKey: 'father_title',
                extraActions: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const RoleSelectionScreen(),
                        ),
                      );
                    },
                    tooltip: langCode == 'ar' ? 'تغيير الواجهة' : 'Change Mode',
                  ),
                ],
              ),
              body: Stack(
                children: [
                  // Main Dashboard View
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Card
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 36),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        langCode == 'ar' ? 'مرحبًا بالوالد العزيز' : 'Welcome Dear Father',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.darkNavy,
                                        ),
                                      ),
                                      Text(
                                        langCode == 'ar' ? 'أتمنى لك يومًا صحيًا ملؤه العافية' : 'Wishing you a healthy day',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Central Countdown Widget (Ultra-Accessible, HUGE font)
                          Expanded(
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 32),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    width: 4,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time_filled_rounded,
                                      color: AppColors.primary,
                                      size: hasNextDose ? 54 : 64,
                                    ),
                                    const SizedBox(height: 16),
                                    if (hasNextDose) ...[
                                      Text(
                                        AppLocalization.translate('next_dose_in', langCode),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Medicine Name
                                      Text(
                                        state.nextDoseMedicine!.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.darkNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Ticking Countdown
                                      Text(
                                        _formatDuration(state.nextDoseCountdown!, langCode),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        AppLocalization.translate('no_upcoming_doses', langCode),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.darkNavy,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Testing Simulation Tools (At Bottom)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  langCode == 'ar' ? '🛠️ أدوات المحاكاة والاختبار السريع:' : '🛠️ Simulation & Quick Testing Tools:',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.read<MedicineCubit>().demoTriggerAlarm('بنادول - Panadol');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(
                                          langCode == 'ar' ? 'رنين إنذار بنادول' : 'Ring Panadol Alarm',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.read<MedicineCubit>().demoTriggerAlarm('أسبيرين - Aspirin');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(
                                          langCode == 'ar' ? 'رنين إنذار أسبيرين' : 'Ring Aspirin Alarm',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Full Screen Interruptive Alarm Overlay
                  if (state.isAlarmActive && state.activeAlarmMedicine != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.92),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Icon Pulse
                              Column(
                                children: [
                                  const SizedBox(height: 24),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.error.withValues(alpha: 0.2),
                                    ),
                                    padding: const EdgeInsets.all(24),
                                    child: const Icon(
                                      Icons.ring_volume_rounded,
                                      color: AppColors.error,
                                      size: 72,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Title
                                  Text(
                                    AppLocalization.translate('alarm_title', langCode),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Medicine Detail text
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    child: Text(
                                      state.activeAlarmMedicine!.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Escalation warning indicator
                              Column(
                                children: [
                                  Text(
                                    AppLocalization.translate('escalation_warning', langCode),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.orangeAccent.shade200,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (state.isSonAlertActive) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      langCode == 'ar'
                                          ? '⚠️ تم تنبيه الابن بالفعل في التطبيق'
                                          : '⚠️ Caregiver has been alerted in app',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  if (state.isSmsSent) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      langCode == 'ar'
                                          ? '✉️ تم إرسال رسالة SMS الطوارئ للابن!'
                                          : '✉️ Emergency SMS has been sent to Caregiver!',
                                      style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  const SizedBox(height: 32),
                                  // Big Green Confirm Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 90,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.read<MedicineCubit>().confirmDoseTaken();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalization.translate('taken_success', langCode),
                                            ),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        elevation: 8,
                                      ),
                                      child: Text(
                                        AppLocalization.translate('mark_as_taken', langCode),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
