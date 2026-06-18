import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization.dart';
import '../../../core/theme.dart';
import '../../../logic/navigation/navigation_cubit.dart';
import '../../../logic/medicine/medicine_cubit.dart';
import '../../../logic/language/language_cubit.dart';
import '../../widgets/theme_language_header.dart';
import '../role_selection_screen.dart';
import 'tabs/medication_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/settings_tab.dart';

class CaregiverDashboard extends StatelessWidget {
  const CaregiverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      const MedicationTab(),
      const ReportsTab(),
      const MapTab(),
      const SettingsTab(),
    ];

    return BlocBuilder<NavigationCubit, int>(
      builder: (context, activeIndex) {
        return Scaffold(
          appBar: ThemeLanguageHeader(
            titleKey: 'caregiver_title',
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
          body: BlocBuilder<MedicineCubit, MedicineState>(
            builder: (context, medState) {
              return Column(
                children: [
                  // 1. تنبيه فوري لواجهة مقدم الرعاية عند انتهاء مهلة متلقي الرعاية
                  if (medState.isSonAlertActive)
                    Container(
                      color: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              langCode == 'ar'
                                  ? ' تحذير: متلقي الرعاية لم يأخذ الجرعة في الوقت المحدد!'
                                  : ' Alert: Care Recipient did not confirm taking the dose on time!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // 2. زر الاستجابة لإيقاف التصعيد (الـ SMS)
                          ElevatedButton(
                            onPressed: () {
                              context.read<MedicineCubit>().caregiverAcknowledge();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              langCode == 'ar' ? 'تم الاستجابة من قِبل مقدم الرعاية' : 'Acknowledge',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // تنبيه إرسال الـ SMS
                  if (medState.isSmsSent)
                    Container(
                      color: AppColors.warning,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.sms_rounded, color: AppColors.darkNavy, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              langCode == 'ar'
                                  ? ' تم تفعيل نظام الـ SMS للطوارئ لعدم الاستجابة!'
                                  : ' Emergency SMS system activated due to no response!',
                              style: const TextStyle(
                                color: AppColors.darkNavy,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: tabs[activeIndex],
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: activeIndex,
              onTap: (index) => context.read<NavigationCubit>().selectTab(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: isDark ? Colors.white60 : Colors.black45,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.medication_liquid_rounded),
                  label: AppLocalization.translate('tab_medication', langCode),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.analytics_rounded),
                  label: AppLocalization.translate('tab_reports', langCode),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.map_rounded),
                  label: AppLocalization.translate('tab_map', langCode),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_rounded),
                  label: AppLocalization.translate('tab_settings', langCode),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
