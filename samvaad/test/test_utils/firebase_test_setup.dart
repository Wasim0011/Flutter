import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared Firebase mock initialization for widget/unit tests.
///
/// `flutter test` can reuse process/isolate state across test files in
/// ways that aren't fully visible from application code, so a locally
/// tracked "already initialized" boolean isn't reliable here — it was
/// still allowing a second `initializeApp` call through. Instead, we
/// treat Firebase's own `duplicate-app` error as the authoritative
/// signal that setup already happened, and simply continue: the
/// existing `[DEFAULT]` app already carries the options this test
/// suite expects, since every test file requests the identical
/// FirebaseOptions below.
Future<void> ensureFirebaseTestSetup() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'samvaad-test-project',
      ),
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    // Already initialized elsewhere in this test run — safe to continue.
  }
}