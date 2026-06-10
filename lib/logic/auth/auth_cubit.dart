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

// تم حذف حالة AuthVerificationSent نهائياً لمنع تعليق الشاشة

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String? message;
  final Map<String, String>? fieldErrors;
  const AuthError({this.message, this.fieldErrors});
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _checkInitialAuth();
    _monitorAuthState();
  }

  void _checkInitialAuth() async {
    final email = await _authRepository.getCurrentUserEmail();
    if (email != null) {
      emit(AuthAuthenticated(email));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  void _monitorAuthState() {
    _authRepository.authStateChanges.listen((email) {
      if (email != null) {
        emit(AuthAuthenticated(email));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> updateEmergencyPhone(String phone) async {
    await _authRepository.saveEmergencyPhone(phone);
  }

  Future<String?> getEmergencyPhone() async {
    return await _authRepository.getEmergencyPhone();
  }

  // Regex validations
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
      // بعد نجاح تسجيل الدخول، نبث حالة النجاح مباشرة
      emit(AuthAuthenticated(email.trim()));
    } catch (e) {
      String errMsg = langCode == 'ar'
          ? 'فشل تسجيل الدخول: الرجاء التحقق من البيانات'
          : 'Login failed: Please check credentials';
      if (e is fb.FirebaseAuthException) {
        if (e.message != null) {
          errMsg = e.message!;
        }
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
      // هنا التعديل السحري: طيران مباشر لصفحة الأدوار فور نجاح التسجيل!
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