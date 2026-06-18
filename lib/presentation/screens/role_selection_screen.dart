import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization.dart';
import '../../core/theme.dart';
import '../../logic/role/role_cubit.dart';
import '../../logic/language/language_cubit.dart';
import '../widgets/theme_language_header.dart';
import 'care_recipient/care_recipient_dashboard.dart';
import 'caregiver/caregiver_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isNavigating = false;

  void _navigateToDashboard(BuildContext context, UserRole role) {
    if (role == UserRole.caregiver) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CaregiverDashboard()),
            (route) => false,
      );
    } else if (role == UserRole.careRecipient) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CareRecipientDashboard()),
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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
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

                  // Caregiver Option
                  Expanded(
                    child: _buildRoleCard(
                      context: context,
                      titleKey: 'role_caregiver',
                      icon: Icons.family_restroom_rounded,
                      color: AppColors.primary,
                      onTap: () async {
                        if (_isNavigating) return;
                        setState(() => _isNavigating = true);
                        await roleCubit.selectRole(UserRole.caregiver);
                        if (context.mounted) {
                          _navigateToDashboard(context, UserRole.caregiver);
                        }
                      },
                      isDark: isDark,
                      langCode: langCode,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Care Recipient Option
                  Expanded(
                    child: _buildRoleCard(
                      context: context,
                      titleKey: 'role_elderly',
                      icon: Icons.elderly_rounded,
                      color: AppColors.darkNavy,
                      onTap: () async {
                        if (_isNavigating) return;
                        setState(() => _isNavigating = true);
                        await roleCubit.selectRole(UserRole.careRecipient);
                        if (context.mounted) {
                          _navigateToDashboard(context, UserRole.careRecipient);
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
          if (_isNavigating)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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
              color: isDark ? color.withOpacity(0.4) : color.withOpacity(0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
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
