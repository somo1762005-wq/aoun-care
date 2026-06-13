import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';

enum UserRole { none, son, father }

class RoleCubit extends Cubit<UserRole> {
  final AuthRepository _authRepository;

  RoleCubit(this._authRepository) : super(UserRole.none) {
    _loadRole();
    // مراقبة حالة المصادقة لإعادة تحميل الدور عند تسجيل الدخول/الخروج
    _authRepository.authStateChanges.listen((email) {
      if (email != null) {
        // ننتظر قليلاً للتأكد من مزامنة البيانات في AuthRepository
        Future.delayed(const Duration(seconds: 1), () => _loadRole());
      } else {
        emit(UserRole.none);
      }
    });
  }

  void _loadRole() {
    // جلب الدور دون تعطيل الـ UI
    _authRepository.getRole().then((roleStr) {
      if (roleStr == 'son') {
        emit(UserRole.son);
      } else if (roleStr == 'father') {
        emit(UserRole.father);
      } else {
        emit(UserRole.none);
      }
    }).catchError((_) {
      emit(UserRole.none);
    });
  }

  Future<void> selectRole(UserRole role) async {
    // 1. بث الحالة فوراً وبشكل لحظي (Instant Emit)
    emit(role);

    String roleStr = 'none';
    if (role == UserRole.son) {
      roleStr = 'son';
    } else if (role == UserRole.father) {
      roleStr = 'father';
    }

    // 2. الحفظ في الخلفية تماماً وبدون استخدام كلمة await نهائياً
    // لضمان عدم تعليق الشاشة وتجنب الـ Deadlocks
    _authRepository.saveRole(roleStr).catchError((e) {
      // تسجيل الخطأ فقط في حالة الفشل دون التأثير على المستخدم
      print("Background save error: $e");
    });
  }

  void clearRole() {
    emit(UserRole.none);
    _authRepository.saveRole('none');
  }
}
