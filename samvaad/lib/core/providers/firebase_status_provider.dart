import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_status_provider.g.dart';

/// Temporary connectivity proof for Milestone 2.1 only.
///
/// This provider's only job is to confirm `Firebase.initializeApp()`
/// actually succeeded and the app is talking to the real Samvaad
/// Firebase project — not a placeholder or misconfigured one. It has
/// no role beyond this milestone and is deleted once Milestone 2.2's
/// real AuthRepository gives SplashPage something meaningful to read
/// instead.
@riverpod
String firebaseStatus(Ref ref) {
  final FirebaseApp app = Firebase.app();
  return 'Firebase connected — project: ${app.options.projectId}';
}