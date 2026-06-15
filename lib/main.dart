import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/notification_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/medicine_repository.dart';
import 'logic/theme/theme_cubit.dart';
import 'logic/language/language_cubit.dart';
import 'logic/auth/auth_cubit.dart';
import 'logic/role/role_cubit.dart';
import 'logic/medicine/medicine_cubit.dart';
import 'logic/navigation/navigation_cubit.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/role_selection_screen.dart';
import 'presentation/screens/father/father_dashboard.dart';
import 'presentation/screens/son/son_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully!");
  } catch (e, stack) {
    debugPrint("Firebase initialization failed: $e\n$stack");
  }

  try {
    await NotificationService().initialize();
  } catch (e, stack) {
    debugPrint("NotificationService initialization failed: $e\n$stack");
  }

  if (!kIsWeb) {
    await Permission.notification.request();
  }

  // إنشاء الـ Repositories بأمان
  late AuthRepository authRepository;
  late MedicineRepository medicineRepository;

  try {
    authRepository = AuthRepository();
    medicineRepository = MedicineRepository(authRepository);
  } catch (e) {
    debugPrint("Caught repository crash due to Firebase. Instantiating safe fallback.");
    authRepository = AuthRepository();
    medicineRepository = MedicineRepository(authRepository);
  }

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<MedicineRepository>.value(value: medicineRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()),
          // استدعاء دالة الفحص الأوتوماتيكية عند التشغيل لتسجيل الدخول لمرة واحدة
          BlocProvider<AuthCubit>(create: (_) => AuthCubit(authRepository)),
          BlocProvider<RoleCubit>(create: (_) => RoleCubit(authRepository)),
          BlocProvider<NavigationCubit>(create: (_) => NavigationCubit()),
          BlocProvider<MedicineCubit>(
            create: (_) => MedicineCubit(
              medicineRepository: medicineRepository,
              authRepository: authRepository,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final langCode = context.watch<LanguageCubit>().state;

    return MaterialApp(
      title: 'Aoun Care - عوْن',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      locale: Locale(langCode),

      // تفعيل الدمج الذكي للخطوط في الـ Light Theme
      theme: AppTheme.lightTheme.copyWith(
        textTheme: AppTheme.lightTheme.textTheme.apply(
          fontFamily: 'ModernNo20', // الخط الأساسي للإنجليزي والأرقام
          fontFamilyFallback: const ['AppleEmoji'],
        ),
      ),

      // تفعيل الدمج الذكي للخطوط في الـ Dark Theme
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: AppTheme.darkTheme.textTheme.apply(
          fontFamily: 'ModernNo20', // الخط الأساسي للإنجليزي والأرقام
          fontFamilyFallback: const ['AppleEmoji'],
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // الدخول المباشر عند نجاح المصادقة
        if (authState is AuthAuthenticated) {
          return BlocBuilder<RoleCubit, UserRole>(
            builder: (context, roleState) {
              if (roleState == UserRole.none) {
                return const RoleSelectionScreen();
              } else if (roleState == UserRole.son) {
                return const SonDashboard();
              } else if (roleState == UserRole.father) {
                return const FatherDashboard();
              }
              return const RoleSelectionScreen();
            },
          );
        }

        // إذا كانت الحالة AuthInitial أو AuthError يفتح شاشة الترحيب/التسجيل المباشر
        return const WelcomeScreen();
      },
    );
  }
}