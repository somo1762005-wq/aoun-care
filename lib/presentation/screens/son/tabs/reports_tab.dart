import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/localization.dart';
import '../../../../core/theme.dart';
import '../../../../logic/medicine/medicine_cubit.dart';
import '../../../../logic/language/language_cubit.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<MedicineCubit, MedicineState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalization.translate('weekly_reports', langCode),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: state.logs.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalization.translate('no_activity', langCode),
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black45),
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.logs.length,
                        itemBuilder: (context, index) {
                          final log = state.logs[index];
                          final timeStr = intl.DateFormat('HH:mm - yyyy/MM/dd').format(log.timestamp);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline Circle indicator
                                Column(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: log.takenByFather 
                                            ? AppColors.success.withValues(alpha: 0.15) 
                                            : AppColors.error.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        log.takenByFather 
                                            ? Icons.check_circle_rounded 
                                            : Icons.cancel_rounded,
                                        color: log.takenByFather ? AppColors.success : AppColors.error,
                                        size: 20,
                                      ),
                                    ),
                                    if (index != state.logs.length - 1)
                                      Container(
                                        width: 2,
                                        height: 50,
                                        color: isDark ? Colors.white24 : Colors.black12,
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                
                                // Timeline Card Content
                                Expanded(
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    color: isDark ? AppColors.cardDark : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isDark ? Colors.white10 : Colors.black12,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLocalization.translate(
                                              log.takenByFather ? 'taken_log' : 'missed_log',
                                              langCode,
                                              arguments: {
                                                'name': log.medicineName,
                                                'time': log.timeLabel,
                                              },
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              fontSize: 11,
                                            ),
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
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
