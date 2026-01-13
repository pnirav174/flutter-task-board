import 'package:take_home_assignment/features/auth/domain/user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> signIn(String email, String password);
  Future<AuthUser> signUp(String email, String password);
  Future<void> signOut();
  AuthUser? get currentUser;
}
