import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization.dart';
import '../../logic/theme/theme_cubit.dart';
import '../../logic/language/language_cubit.dart';

class ThemeLanguageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String titleKey;
  final bool showBackButton;
  final List<Widget>? extraActions;

  const ThemeLanguageHeader({
    super.key,
    required this.titleKey,
    this.showBackButton = false,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final languageCubit = context.watch<LanguageCubit>();
    final langCode = languageCubit.state;
    final isDark = themeCubit.state == ThemeMode.dark;

    return AppBar(
      title: Text(
        AppLocalization.translate(titleKey, langCode),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'ModernNo20', // التأكيد على خط الآيفون للعنوان
        ),
      ),
      leading: showBackButton
          ? IconButton(
        icon: Icon(
          langCode == 'ar' ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
          size: 30, // تكبير بسيط ليتناسب مع أبعاد خط الآيفون الأنيق
        ),
        onPressed: () => Navigator.of(context).pop(),
      )
          : null,
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        if (extraActions != null) ...extraActions!,
        // زر تبديل اللغة (Language Toggle)
        TextButton(
          onPressed: () => languageCubit.toggleLanguage(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // زيادة مساحة الضغط لراحة المستخدم
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            langCode == 'ar' ? 'English' : 'العربية',
            style: TextStyle(
              fontSize: 15, // حجم موزون ومثالي للقراءة
              fontWeight: FontWeight.w700,
              fontFamily: 'ModernNo20',
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        // زر تبديل الثيم (Theme Toggle)
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: const BoxConstraints(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey<bool>(isDark),
              color: isDark ? Colors.amber : Colors.blueGrey[800],
              size: 24,
            ),
          ),
          onPressed: () => themeCubit.toggleTheme(),
        ),
        const SizedBox(width: 12), // مسافة أمان جانبية متناسقة مع حواف الشاشة
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}