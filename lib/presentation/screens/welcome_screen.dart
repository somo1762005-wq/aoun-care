import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization.dart';
import '../../logic/language/language_cubit.dart';
import '../../logic/theme/theme_cubit.dart';
import '../../core/theme.dart';
import 'package:aoun_new/presentation/screens/auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, String>> onboardingData = [
      {
        "title": langCode == 'ar' ? "مرحباً بك في" : "Welcome to",
        "special": langCode == 'ar' ? "\nعوْن" : "\nAoun",
        "desc": "",
      },
      {
        "title": langCode == 'ar' ? "عوْن معك في كل لحظة اهتمام" : "Aoun is with you in every moment of care",
        "special": "",
        "desc": langCode == 'ar'
            ? "تذكيرات، ومتابعة، وطمأنينة في مكان واحد 🚀"
            : "Reminders, tracking, and peace of mind all in one place 🚀",
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header with theme and language controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeMode) {
                        return IconButton(
                          icon: Icon(
                            themeMode == ThemeMode.dark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                          ),
                          onPressed: () {
                            context.read<ThemeCubit>().toggleTheme();
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<LanguageCubit, String>(
                      builder: (context, langCode) {
                        return IconButton(
                          icon: Text(
                            langCode == 'ar' ? 'EN' : 'ع',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            context.read<LanguageCubit>().toggleLanguage();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Middle part: PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Centered Logo/Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'ModernNo20',
                              height: 1.4,
                              color: isDark ? Colors.white : AppColors.darkNavy,
                            ),
                            children: [
                              TextSpan(text: onboardingData[index]["title"]),
                              TextSpan(
                                text: onboardingData[index]["special"],
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'ModernNo20',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          onboardingData[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'ModernNo20',
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom part: Dots and start button
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingData.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < onboardingData.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == onboardingData.length - 1
                              ? AppLocalization.translate('start_now', langCode)
                              : (langCode == 'ar' ? 'التالي' : 'Next'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ModernNo20',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Protection for language button tap
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: Container(
                  height: 160,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}