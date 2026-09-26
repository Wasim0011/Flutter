import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/calling/domain/entities/call.dart';
import 'package:samvaad/features/calling/presentation/providers/call_providers.dart';
import 'package:samvaad/features/calling/presentation/providers/incoming_call_providers.dart';
import '../../fakes/fake_call_repository.dart';

void main() {
  late FakeCallRepository fakeRepo;
  late ProviderContainer container;

  const String userId = 'user-a';
  const String callerId = 'user-b';

  setUp(() {
    fakeRepo = FakeCallRepository();
    container = ProviderContainer(
      overrides: [callRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() {
    fakeRepo.dispose();
    container.dispose();
  });

  test('emits null when there is no ringing call for the user', () async {
    // nextIncomingCallProvider is autoDispose — a bare container.read()
    // doesn't keep it alive across the async gap before the stream's
    // first event arrives, so Riverpod disposes it mid-flight before
    // it can emit. container.listen() establishes a real subscriber,
    // keeping the provider alive for the duration of this test (same
    // fix as Phase 3's message_thread_controller_test.dart).
    final sub = container.listen(nextIncomingCallProvider(userId), (previous, next) {});
    addTearDown(sub.close);

    final Call? result = await container.read(nextIncomingCallProvider(userId).future);
    expect(result, isNull);
  });

  test('emits the call when someone else calls this user', () async {
    final sub = container.listen(nextIncomingCallProvider(userId), (previous, next) {});
    addTearDown(sub.close);

    await fakeRepo.startCall(callerId: callerId, calleeIds: [userId]);
    await Future<void>.delayed(Duration.zero);

    final AsyncValue<Call?> state = container.read(nextIncomingCallProvider(userId));
    expect(state.value, isNotNull);
    expect(state.value!.callerId, callerId);
  });

  test('does not surface a call the user started themselves', () async {
    final sub = container.listen(nextIncomingCallProvider(userId), (previous, next) {});
    addTearDown(sub.close);

    await fakeRepo.startCall(callerId: userId, calleeIds: [callerId]);
    await Future<void>.delayed(Duration.zero);

    final AsyncValue<Call?> state = container.read(nextIncomingCallProvider(userId));
    expect(state.value, isNull);
  });
}