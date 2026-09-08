import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad/features/auth/domain/repositories/auth_repository.dart';
import 'package:samvaad/features/auth/presentation/controllers/phone_entry_controller.dart';
import 'package:samvaad/features/auth/presentation/providers/auth_providers.dart';
import '../../fakes/fake_auth_repository.dart';
import 'package:samvaad/core/error/failure.dart';

void main() {
  late FakeAuthRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo as AuthRepository),
      ],
    );
  });

  tearDown(() {
    fakeRepo.dispose();
    container.dispose();
  });

  test('starts in idle state', () {
    final state = container.read(phoneEntryControllerProvider);
    expect(state, isA<PhoneEntryIdle>());
  });

  test('submit() transitions to submitting then sent on success', () async {
    final future = container
        .read(phoneEntryControllerProvider.notifier)
        .submit('+919999999999');

    expect(container.read(phoneEntryControllerProvider), isA<PhoneEntrySubmitting>());

    await future;

    final state = container.read(phoneEntryControllerProvider);
    expect(state, isA<PhoneEntrySent>());
    expect((state as PhoneEntrySent).phoneNumber, '+919999999999');
  });

  test('submit() transitions to failed on repository failure', () async {
    fakeRepo.sendOtpFailure = const Failure.network('offline');

    await container
        .read(phoneEntryControllerProvider.notifier)
        .submit('+919999999999');

    final state = container.read(phoneEntryControllerProvider);
    expect(state, isA<PhoneEntryFailed>());
  });

  test('reset() returns to idle', () async {
    await container
        .read(phoneEntryControllerProvider.notifier)
        .submit('+919999999999');

    container.read(phoneEntryControllerProvider.notifier).reset();

    expect(container.read(phoneEntryControllerProvider), isA<PhoneEntryIdle>());
  });
}