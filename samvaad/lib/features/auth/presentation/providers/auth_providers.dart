import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

/// The app-wide [AuthRepository] instance.
///
/// Everything that needs to sign in/out or check auth state depends on
/// this provider, not on `FirebaseAuthRepository` directly — tests
/// override this single provider with a fake, and nothing else in the
/// dependency graph needs to change.
@riverpod
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository();
}

/// Live stream of the current auth state, for the router guard
/// (Milestone 2.6) and any widget that needs to react to sign-in/out.
@riverpod
Stream<AppUser?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}