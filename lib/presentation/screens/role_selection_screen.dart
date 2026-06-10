import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization.dart';
import '../../core/theme.dart';
import '../../logic/role/role_cubit.dart';
import '../../logic/language/language_cubit.dart';
import '../widgets/theme_language_header.dart';
import 'father/father_dashboard.dart';
import 'son/son_dashboard.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _navigateToDashboard(BuildContext context, UserRole role) {
    if (role == UserRole.son) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SonDashboard()),
        (route) => false,
      );
    } else if (role == UserRole.father) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const FatherDashboard()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final roleCubit = context.read<RoleCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const ThemeLanguageHeader(titleKey: 'role_selection_title'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Subtitle instruction
              Text(
                AppLocalization.translate('role_selection_subtitle', langCode),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 48),

              // Caregiver Option (Son)
              Expanded(
                child: _buildRoleCard(
                  context: context,
                  titleKey: 'role_caregiver',
                  icon: Icons.family_restroom_rounded,
                  color: AppColors.primary,
                  onTap: () async {
                    await roleCubit.selectRole(UserRole.son);
                    if (context.mounted) {
                      _navigateToDashboard(context, UserRole.son);
                    }
                  },
                  isDark: isDark,
                  langCode: langCode,
                ),
              ),
              const SizedBox(height: 24),

              // Elderly Option (Father)
              Expanded(
                child: _buildRoleCard(
                  context: context,
                  titleKey: 'role_elderly',
                  icon: Icons.elderly_rounded,
                  color: AppColors.darkNavy,
                  onTap: () async {
                    await roleCubit.selectRole(UserRole.father);
                    if (context.mounted) {
                      _navigateToDashboard(context, UserRole.father);
                    }
                  },
                  isDark: isDark,
                  langCode: langCode,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String titleKey,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required String langCode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              // Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  AppLocalization.translate(titleKey, langCode),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
