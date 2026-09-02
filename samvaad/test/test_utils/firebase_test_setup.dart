import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared Firebase mock initialization for widget/unit tests.
///
/// `flutter test` runs every test file in one process, and Firebase
/// only allows a single `[DEFAULT]` app to exist at a time. Centralizing
/// setup here — guarded so it only runs once no matter how many test
/// files call it — avoids both `duplicate-app` errors (calling this
/// twice) and `no-app` errors (a test file that builds Firebase-dependent
/// widgets without ever calling this at all).
bool _initialized = false;

Future<void> ensureFirebaseTestSetup() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (_initialized) return;
  _initialized = true;

  setupFirebaseCoreMocks();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'test-api-key',
      appId: 'test-app-id',
      messagingSenderId: 'test-sender-id',
      projectId: 'samvaad-test-project',
    ),
  );
}