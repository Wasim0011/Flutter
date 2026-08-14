import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_provider.g.dart';

/// Minimal, deliberately trivial provider whose only job in Milestone 5
/// is to prove the Riverpod code-generation + DI pipeline works
/// end-to-end: `@riverpod` annotation → generated provider → consumed
/// by a widget via `ConsumerWidget`.
///
/// This is intentionally *not* a real feature. Once Auth/Chat/Calling
/// features exist, this file can be deleted — it exists only as the
/// foundation's proof-of-wiring, the DI equivalent of a "hello world."
@riverpod
String appInfo(Ref ref) {
  return 'Samvaad v0.1.0 — foundation build';
}