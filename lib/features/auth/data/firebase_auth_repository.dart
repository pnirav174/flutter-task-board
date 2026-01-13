import 'package:firebase_auth/firebase_auth.dart';
import 'package:take_home_assignment/features/auth/domain/auth_repository.dart';
import 'package:take_home_assignment/features/auth/domain/user.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUser(id: user.uid, email: user.email ?? '');
    });
  }

  @override
  AuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AuthUser(id: user.uid, email: user.email ?? '');
  }

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Sign in failed');
    return AuthUser(id: user.uid, email: user.email ?? '');
  }

  @override
  Future<AuthUser> signUp(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Sign up failed');
    return AuthUser(id: user.uid, email: user.email ?? '');
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
