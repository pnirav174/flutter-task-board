import 'dart:async';
import 'package:flutter_task_board/features/auth/domain/auth_repository.dart';
import 'package:flutter_task_board/features/auth/domain/user.dart';
import 'package:uuid/uuid.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  final _uuid = const Uuid();

  MockAuthRepository() {
    // Simulate initial check
    Future.delayed(const Duration(milliseconds: 500), () {
      _controller.add(null);
    });
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signIn(String email, String password) async {
    await Future.delayed(
      const Duration(milliseconds: 1000),
    ); // Simulate network
    if (password == 'fail') throw Exception('Invalid credentials');

    final user = AuthUser(id: 'mock-${_uuid.v4()}', email: email);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signUp(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final user = AuthUser(id: 'mock-${_uuid.v4()}', email: email);
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _controller.add(null);
  }
}
