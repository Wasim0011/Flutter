import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Auth implementation of [AuthRepository].
///
/// This is the ONLY file in the app that should import
/// `package:firebase_auth`. Everything above it (presentation, other
/// features) depends on the domain `AuthRepository` interface —
/// swapping auth providers later would mean writing a new class here,
/// not touching any other file.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _firebaseAuth;

  @override
  Future<Result<PhoneVerificationSent>> sendOtp(String phoneNumber) async {
    final Completer<Result<PhoneVerificationSent>> completer = Completer();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        if (!completer.isCompleted) {
          try {
            await _firebaseAuth.signInWithCredential(credential);
          } on fb.FirebaseAuthException catch (e) {
            // ignore: avoid_print
            print('Auto-verification sign-in failed: ${e.code}');
          }
        }
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.complete(Result.failure(_mapAuthException(e)));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            Result.success(PhoneVerificationSent(verificationId: verificationId)),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // No-op: if codeSent already fired, the caller already has
        // what it needs. If it hasn't, verificationFailed or a
        // genuine timeout will have already resolved the completer.
      },
    );

    return completer.future;
  }

  @override
  Future<Result<AppUser>> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final fb.PhoneAuthCredential credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final fb.UserCredential userCredential =
      await _firebaseAuth.signInWithCredential(credential);

      final fb.User? user = userCredential.user;
      if (user == null) {
        return const Result.failure(
          Failure.unexpected('Sign-in succeeded but no user was returned.'),
        );
      }

      return Result.success(_toAppUser(user));
    } on fb.FirebaseAuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
          (fb.User? user) => user == null ? null : _toAppUser(user),
    );
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unexpected(e.toString()));
    }
  }

  AppUser _toAppUser(fb.User user) {
    return AppUser(
      id: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      displayName: user.displayName,
    );
  }

  Failure _mapAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return const Failure.validation('That phone number doesn\'t look valid.');
      case 'invalid-verification-code':
        return const Failure.validation('That code is incorrect.');
      case 'session-expired':
        return const Failure.validation('That code has expired. Request a new one.');
      case 'too-many-requests':
        return const Failure.unexpected('Too many attempts. Try again later.');
      case 'network-request-failed':
        return const Failure.network('No internet connection.');
      default:
        return Failure.unexpected(e.message ?? 'Something went wrong (${e.code}).');
    }
  }
}