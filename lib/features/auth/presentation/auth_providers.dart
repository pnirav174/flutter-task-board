import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take_home_assignment/features/auth/data/firebase_auth_repository.dart';
// import 'package:take_home_assignment/features/auth/data/mock_auth_repository.dart';
import 'package:take_home_assignment/features/auth/domain/auth_repository.dart';
import 'package:take_home_assignment/features/auth/domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(FirebaseAuth.instance);
  // return MockAuthRepository();
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});
