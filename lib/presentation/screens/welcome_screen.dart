import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization.dart';
import '../../logic/language/language_cubit.dart';
import '../../core/theme.dart';
import '../widgets/theme_language_header.dart';
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

    // 👈 التعديل الذكي: عرض النص بناءً على لغة واجهة المستخدم الحالية
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
      {
        "title": langCode == 'ar' ? "ابدأ رحلة العناية الذكية بكبير العائلة" : "Start the smart care journey for your family elder",
        "special": "",
        "desc": langCode == 'ar'
            ? "سندك الرقمي للعناية بمن تحب بأمان وسهولة 👴🏼🤝🏻"
            : "Your digital support to care for your loved ones safely and easily 👴🏼🤝🏻",
      },
    ];

    return Scaffold(
      appBar: const ThemeLanguageHeader(titleKey: ''),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 60),

                // الجزء العلوي: الشعار الثابت والمتوهج
                Center(
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 35,
                          spreadRadius: 8,
                        )
                      ],
                    ),
                    child: Center(
                      child: Container(
                        height: 140,
                        width: 140,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // الجزء الأوسط: الصفحات الساحبة
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
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'SFPro',
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
                                    fontFamily: 'SFPro',
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
                              fontFamily: 'SFPro',
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // الجزء السفلي: النقاط وزر الانطلاق
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
                              fontFamily: 'SFPro',
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

            // حماية لتمرير ضغطة زر اللغة بنجاح
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
      ),
    );
  }
}