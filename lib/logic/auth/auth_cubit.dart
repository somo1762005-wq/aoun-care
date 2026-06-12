import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../data/repositories/auth_repository.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String email;
  const AuthAuthenticated(this.email);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String? message;
  final Map<String, String>? fieldErrors;
  const AuthError({this.message, this.fieldErrors});
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    // تشغيل الفحص الأولي والمراقبة دون انتظار متزامن يعطل الـ UI
    _checkInitialAuth();
    _monitorAuthState();
  }

  void _checkInitialAuth() {
    // نستخدم then بدلاً من await بداخل الـ constructor لتجنب تعليق الشاشة
    _authRepository.getCurrentUserEmail().then((email) {
      if (email != null) {
        emit(AuthAuthenticated(email));
      } else {
        emit(AuthUnauthenticated());
      }
    }).catchError((_) {
      emit(AuthUnauthenticated());
    });
  }

  void _monitorAuthState() {
    _authRepository.authStateChanges.listen((email) {
      if (email != null) {
        emit(AuthAuthenticated(email));
      } else {
        emit(AuthUnauthenticated());
      }
    }, onError: (error) {
      emit(AuthUnauthenticated());
    });
  }

  Future<void> updateEmergencyPhone(String phone) async {
    await _authRepository.saveEmergencyPhone(phone);
  }

  Future<String?> getEmergencyPhone() async {
    return await _authRepository.getEmergencyPhone();
  }

  final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  final RegExp _phoneRegExp = RegExp(
    r'^\+?[0-9]{8,15}$',
  );

  Future<void> login(String email, String password, String langCode) async {
    emit(AuthLoading());

    final errors = <String, String>{};
    if (email.trim().isEmpty) {
      errors['email'] = langCode == 'ar' ? 'البريد الإلكتروني مطلوب' : 'Email is required';
    } else if (!_emailRegExp.hasMatch(email.trim())) {
      errors['email'] = langCode == 'ar' ? 'بريد إلكتروني غير صالح' : 'Invalid email address';
    }

    if (password.isEmpty) {
      errors['password'] = langCode == 'ar' ? 'كلمة المرور مطلوبة' : 'Password is required';
    }

    if (errors.isNotEmpty) {
      emit(AuthError(fieldErrors: errors));
      return;
    }

    try {
      await _authRepository.login(email.trim(), password);
      // التأكد من بث الحالة فوراً بعد النجاح
      emit(AuthAuthenticated(email.trim()));
    } catch (e) {
      String errMsg = langCode == 'ar'
          ? 'فشل تسجيل الدخول: الرجاء التحقق من البيانات'
          : 'Login failed: Please check credentials';
      if (e is fb.FirebaseAuthException && e.message != null) {
        errMsg = e.message!;
      }
      emit(AuthError(message: errMsg));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String phone,
    required String langCode,
  }) async {
    emit(AuthLoading());

    final errors = <String, String>{};

    if (email.trim().isEmpty) {
      errors['email'] = langCode == 'ar' ? 'البريد الإلكتروني مطلوب' : 'Email is required';
    } else if (!_emailRegExp.hasMatch(email.trim())) {
      errors['email'] = langCode == 'ar' ? 'بريد إلكتروني غير صالح' : 'Invalid email address';
    }

    if (password.isEmpty) {
      errors['password'] = langCode == 'ar' ? 'كلمة المرور مطلوبة' : 'Password is required';
    } else if (password.length < 8) {
      errors['password'] = langCode == 'ar'
          ? 'كلمة المرور يجب أن لا تقل عن 8 أحرف'
          : 'Password must be at least 8 characters';
    }

    if (phone.trim().isEmpty) {
      errors['phone'] = langCode == 'ar' ? 'رقم هاتف الابن مطلوب' : 'Son\'s phone number is required';
    } else if (!_phoneRegExp.hasMatch(phone.trim())) {
      errors['phone'] = langCode == 'ar'
          ? 'رقم هاتف غير صحيح'
          : 'Invalid phone format';
    }

    if (errors.isNotEmpty) {
      emit(AuthError(fieldErrors: errors));
      return;
    }

    try {
      await _authRepository.register(email.trim(), password, phone.trim());
      emit(AuthAuthenticated(email.trim()));
    } catch (e) {
      String errMsg = langCode == 'ar'
          ? 'فشل إنشاء الحساب: البريد الإلكتروني قد يكون مستخدمًا بالفعل'
          : 'Registration failed: Email might be already in use';
      if (e is fb.FirebaseAuthException && e.message != null) {
        errMsg = e.message!;
      }
      emit(AuthError(message: errMsg));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(const AuthError(message: 'Logout failed'));
    }
  }

  void clearErrors() {
    emit(AuthInitial());
  }
}
