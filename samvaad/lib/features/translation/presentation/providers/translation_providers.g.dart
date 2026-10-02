// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(signInterpretationRepository)
final signInterpretationRepositoryProvider =
    SignInterpretationRepositoryProvider._();

final class SignInterpretationRepositoryProvider
    extends
        $FunctionalProvider<
          SignInterpretationRepository,
          SignInterpretationRepository,
          SignInterpretationRepository
        >
    with $Provider<SignInterpretationRepository> {
  SignInterpretationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInterpretationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInterpretationRepositoryHash();

  @$internal
  @override
  $ProviderElement<SignInterpretationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SignInterpretationRepository create(Ref ref) {
    return signInterpretationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInterpretationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInterpretationRepository>(value),
    );
  }
}

String _$signInterpretationRepositoryHash() =>
    r'c494b5df680827667305aa08ee1733c8d4afddf4';
