import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/medicine/medicine_cubit.dart';
import '../../../core/constants/app_colors.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicineCubit, MedicineState>(
      builder: (context, state) {
        final medicine = state.activeAlarmMedicine;
        if (medicine == null) {
          // إذا تم إيقاف المنبه من مكان آخر، نغلق الشاشة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: AppColors.primary,
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
                  'الجرعة: ${medicine.dosageAmount}',
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
                        onPressed: () => context.read<MedicineCubit>().confirmDoseTaken(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
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
                          // هنا يمكن إضافة منطق التأجيل Snooze
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
