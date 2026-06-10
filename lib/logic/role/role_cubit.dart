import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';

enum UserRole { none, son, father }

class RoleCubit extends Cubit<UserRole> {
  final AuthRepository _authRepository;

  RoleCubit(this._authRepository) : super(UserRole.none) {
    _loadRole();
  }

  void _loadRole() async {
    final roleStr = await _authRepository.getRole();
    if (roleStr == 'son') {
      emit(UserRole.son);
    } else if (roleStr == 'father') {
      emit(UserRole.father);
    } else {
      emit(UserRole.none);
    }
  }

  Future<void> selectRole(UserRole role) async {
    String roleStr = 'none';
    if (role == UserRole.son) {
      roleStr = 'son';
    } else if (role == UserRole.father) {
      roleStr = 'father';
    }

    await _authRepository.saveRole(roleStr);
    emit(role);
  }

  void clearRole() async {
    await _authRepository.saveRole('none');
    emit(UserRole.none);
  }
}
