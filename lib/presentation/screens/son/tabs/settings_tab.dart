import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/localization.dart';
import '../../../../core/theme.dart';
import '../../../../logic/auth/auth_cubit.dart';
import '../../../../logic/language/language_cubit.dart';
import '../../../../logic/medicine/medicine_cubit.dart';
import '../../welcome_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  int _fatherBuffer = 30;
  int _sonBuffer = 10;
  final _phoneController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _phoneController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _previewTone(String tone) async {
    if (tone == 'default') return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('raw/$tone.mp3'));
      Future.delayed(const Duration(seconds: 2), () => _audioPlayer.stop());
    } catch (e) {
      debugPrint("Error previewing tone: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    final medState = context.read<MedicineCubit>().state;
    _fatherBuffer = medState.fatherBufferMinutes;
    _sonBuffer = medState.sonBufferMinutes;
    _loadPhone();
  }

  void _loadPhone() async {
    final phone = await context.read<AuthCubit>().getEmergencyPhone();
    if (phone != null && mounted) {
      setState(() {
        _phoneController.text = phone;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // إصلاح دالة المشاركة مع إضافة Debugging
  Future<void> _shareApp(BuildContext context) async {
    const String shareLink = "https://aoun-care.app/download";
    const String shareMessage =
        "أنصحك باستخدام تطبيق عوْن (Aoun Care) للعناية والمتابعة الصحية الذكية لكبار السن والوالدين. يمكنك تحميل التطبيق من الرابط التالي: $shareLink";

    try {
      debugPrint("Attempting to share message: $shareMessage");

      // استخدام Share.share مع التحقق من السياق (Context)
      final result = await Share.share(shareMessage);

      debugPrint("Share result: ${result.status}");
    } catch (e) {
      debugPrint("Error while sharing: $e");
      // في حال فشل الـ Native Share، نظهر SnackBar للتنبيه
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل فتح نافذة المشاركة: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final medCubit = context.read<MedicineCubit>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // About App Card
            Card(
              elevation: 0,
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                title: Text(
                  AppLocalization.translate('about_app', langCode),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  Text(
                    AppLocalization.translate('about_desc', langCode),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Escalation Slider Card
            Card(
              elevation: 0,
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: ExpansionTile(
                  leading: const Icon(Icons.security_update_warning_rounded, color: AppColors.warning),
                  title: Text(
                    AppLocalization.translate('escalation_settings', langCode),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  childrenPadding: const EdgeInsets.only(top: 16, bottom: 8),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalization.translate('escalation_buffer_father', langCode),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_fatherBuffer ${langCode == 'ar' ? 'دقيقة' : 'min'}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        Slider(
                          value: _fatherBuffer.toDouble(),
                          min: 1,
                          max: 60,
                          divisions: 59,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _fatherBuffer = value.toInt();
                            });
                          },
                          onChangeEnd: (value) {
                            medCubit.updateBuffers(_fatherBuffer, _sonBuffer);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalization.translate('escalation_buffer_son', langCode),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_sonBuffer ${langCode == 'ar' ? 'دقيقة' : 'min'}',
                              style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        Slider(
                          value: _sonBuffer.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          activeColor: AppColors.warning,
                          onChanged: (value) {
                            setState(() {
                              _sonBuffer = value.toInt();
                            });
                          },
                          onChangeEnd: (value) {
                            medCubit.updateBuffers(_fatherBuffer, _sonBuffer);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Emergency Phone Card
            Card(
              elevation: 0,
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ExpansionTile(
                  leading: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                  title: Text(
                    langCode == 'ar' ? 'رقم هاتف الابن للطوارئ' : 'Son\'s Emergency Phone',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: langCode == 'ar' ? 'أدخل رقم الهاتف' : 'Enter phone number',
                        prefixIcon: const Icon(Icons.phone),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save_rounded, color: AppColors.primary),
                          onPressed: () async {
                            final newPhone = _phoneController.text.trim();
                            if (newPhone.isNotEmpty) {
                              await context.read<AuthCubit>().updateEmergencyPhone(newPhone);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      langCode == 'ar' ? 'تم تحديث الرقم بنجاح!' : 'Phone number updated successfully!',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Share App tile
            Card(
              elevation: 0,
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.blue),
                title: Text(
                  AppLocalization.translate('share_app', langCode),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => _shareApp(context),
              ),
            ),
            const SizedBox(height: 12),

            // Language quick toggle
            Card(
              elevation: 0,
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: ListTile(
                leading: const Icon(Icons.language_rounded, color: Colors.teal),
                title: Text(
                  AppLocalization.translate('language_settings', langCode),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  langCode == 'ar' ? 'العربية' : 'English',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                onTap: () {
                  context.read<LanguageCubit>().toggleLanguage();
                },
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Alarm Settings Card (Professional UI from User)
            Card(
              elevation: 0,
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ExpansionTile(
                  leading: const Icon(Icons.notification_important_rounded, color: Colors.blue),
                  title: Text(
                    langCode == 'ar' ? 'إعدادات منبه الطوارئ الأبناء' : 'Emergency Alarm Settings',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  initiallyExpanded: true,
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    BlocBuilder<MedicineCubit, MedicineState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Text(
                              langCode == 'ar' 
                                ? 'مستوى صوت المنبه: ${(state.alarmVolume * 100).round()}%'
                                : 'Alarm Volume: ${(state.alarmVolume * 100).round()}%',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Slider(
                              value: state.alarmVolume * 100,
                              min: 0,
                              max: 100,
                              activeColor: Colors.blue,
                              onChanged: (val) => medCubit.updateAlarmSettings(volume: val / 100),
                            ),
                            
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: Colors.blue,
                              title: Text(langCode == 'ar' ? 'تفعيل الاهتزاز النبضي القوي' : 'Enable Strong Vibration'),
                              value: state.isVibrationEnabled,
                              onChanged: (val) => medCubit.updateAlarmSettings(vibration: val),
                            ),
                            
                            const SizedBox(height: 8),
	                            DropdownButtonFormField<String>(
	                              value: state.alarmTone == 'default' ? 'default_tone' : (state.alarmTone == 'sharp' ? 'calm_bell' : 'strong_alarm'),
	                              decoration: InputDecoration(
	                                labelText: langCode == 'ar' ? 'نغمة المنبه' : 'Alarm Tone',
	                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
	                              ),
	                              items: [
	                                DropdownMenuItem(value: 'strong_alarm', child: Text(langCode == 'ar' ? 'إنذار قوي ومتكرر' : 'Strong & Repeated')),
	                                DropdownMenuItem(value: 'calm_bell', child: Text(langCode == 'ar' ? 'جرس هادئ' : 'Calm Bell')),
	                                DropdownMenuItem(value: 'default_tone', child: Text(langCode == 'ar' ? 'النغمة الافتراضية' : 'Default Tone')),
	                              ],
	                              onChanged: (val) {
	                                String mappedTone = 'default';
	                                if (val == 'strong_alarm') mappedTone = 'repeated';
	                                if (val == 'calm_bell') mappedTone = 'sharp';
	                                medCubit.updateAlarmSettings(tone: mappedTone);
	                                _previewTone(mappedTone);
	                              },
	                            ),
	                            const SizedBox(height: 16),
	                            DropdownButtonFormField<int>(
	                              value: state.snoozeMinutes,
	                              decoration: InputDecoration(
	                                labelText: langCode == 'ar' ? 'وقت الغفوة/التكرار' : 'Snooze/Repeat Time',
	                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
	                              ),
	                              items: [
	                                DropdownMenuItem(value: 0, child: Text(langCode == 'ar' ? 'بدون تكرار' : 'No Snooze')),
	                                DropdownMenuItem(value: 3, child: Text(langCode == 'ar' ? 'كل 3 دقائق' : 'Every 3 min')),
	                                DropdownMenuItem(value: 5, child: Text(langCode == 'ar' ? 'كل 5 دقائق' : 'Every 5 min')),
	                                DropdownMenuItem(value: 10, child: Text(langCode == 'ar' ? 'كل 10 دقائق' : 'Every 10 min')),
	                              ],
	                              onChanged: (val) => medCubit.updateAlarmSettings(snooze: val),
	                            ),
	                            SwitchListTile(
	                              contentPadding: EdgeInsets.zero,
	                              activeColor: Colors.blue,
	                              title: Text(langCode == 'ar' ? 'تفعيل الصوت التصاعدي' : 'Enable Ascending Volume'),
	                              value: false,
	                              onChanged: (val) {},
	                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Logout
            Card(
              elevation: 0,
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text(
                  AppLocalization.translate('logout', langCode),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                ),
                onTap: () async {
                  await context.read<AuthCubit>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
