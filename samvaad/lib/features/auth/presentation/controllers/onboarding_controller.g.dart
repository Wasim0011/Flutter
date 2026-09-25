// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userProfileRepository)
final userProfileRepositoryProvider = UserProfileRepositoryProvider._();

final class UserProfileRepositoryProvider
    extends
        $FunctionalProvider<
          UserProfileRepository,
          UserProfileRepository,
          UserProfileRepository
        >
    with $Provider<UserProfileRepository> {
  UserProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserProfileRepository create(Ref ref) {
    return userProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileRepository>(value),
    );
  }
}

String _$userProfileRepositoryHash() =>
    r'61224fb2496ebeb7b1c2a7e8d8126d99a85a14db';

@ProviderFor(OnboardingController)
final onboardingControllerProvider = OnboardingControllerProvider._();

final class OnboardingControllerProvider
    extends $NotifierProvider<OnboardingController, OnboardingState> {
  OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingState>(value),
    );
  }
}

String _$onboardingControllerHash() =>
    r'dec7f0c1f78e3a7433811749e9c5eec0a7bf9059';

abstract class _$OnboardingController extends $Notifier<OnboardingState> {
  OnboardingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OnboardingState, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingState, OnboardingState>,
              OnboardingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(hasCompletedOnboarding)
final hasCompletedOnboardingProvider = HasCompletedOnboardingFamily._();

final class HasCompletedOnboardingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  HasCompletedOnboardingProvider._({
    required HasCompletedOnboardingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hasCompletedOnboardingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hasCompletedOnboardingHash();

  @override
  String toString() {
    return r'hasCompletedOnboardingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return hasCompletedOnboarding(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HasCompletedOnboardingProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hasCompletedOnboardingHash() =>
    r'0314940df574972845142a296d149fab1d513ca3';

final class HasCompletedOnboardingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  HasCompletedOnboardingFamily._()
    : super(
        retry: null,
        name: r'hasCompletedOnboardingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HasCompletedOnboardingProvider call(String userId) =>
      HasCompletedOnboardingProvider._(argument: userId, from: this);

  @override
  String toString() => r'hasCompletedOnboardingProvider';
}

/// The current [CommunicationPreference] for [userId], or null if not
/// yet set. Used by the chat feature to adapt message screen layout.

@ProviderFor(communicationPreference)
final communicationPreferenceProvider = CommunicationPreferenceFamily._();

/// The current [CommunicationPreference] for [userId], or null if not
/// yet set. Used by the chat feature to adapt message screen layout.

final class CommunicationPreferenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<CommunicationPreference?>,
          CommunicationPreference?,
          FutureOr<CommunicationPreference?>
        >
    with
        $FutureModifier<CommunicationPreference?>,
        $FutureProvider<CommunicationPreference?> {
  /// The current [CommunicationPreference] for [userId], or null if not
  /// yet set. Used by the chat feature to adapt message screen layout.
  CommunicationPreferenceProvider._({
    required CommunicationPreferenceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'communicationPreferenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$communicationPreferenceHash();

  @override
  String toString() {
    return r'communicationPreferenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CommunicationPreference?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CommunicationPreference?> create(Ref ref) {
    final argument = this.argument as String;
    return communicationPreference(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CommunicationPreferenceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communicationPreferenceHash() =>
    r'c4148139bc5a84a4d7ab34d1cb2b38db29b88918';

/// The current [CommunicationPreference] for [userId], or null if not
/// yet set. Used by the chat feature to adapt message screen layout.

final class CommunicationPreferenceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CommunicationPreference?>, String> {
  CommunicationPreferenceFamily._()
    : super(
        retry: null,
        name: r'communicationPreferenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The current [CommunicationPreference] for [userId], or null if not
  /// yet set. Used by the chat feature to adapt message screen layout.

  CommunicationPreferenceProvider call(String userId) =>
      CommunicationPreferenceProvider._(argument: userId, from: this);

  @override
  String toString() => r'communicationPreferenceProvider';
}

/// The stored display name for [userId], or null if not set. Used by
/// chat's conversation list and conversation screen to show real
/// names instead of raw user ids.

@ProviderFor(displayName)
final displayNameProvider = DisplayNameFamily._();

/// The stored display name for [userId], or null if not set. Used by
/// chat's conversation list and conversation screen to show real
/// names instead of raw user ids.

final class DisplayNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The stored display name for [userId], or null if not set. Used by
  /// chat's conversation list and conversation screen to show real
  /// names instead of raw user ids.
  DisplayNameProvider._({
    required DisplayNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'displayNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$displayNameHash();

  @override
  String toString() {
    return r'displayNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return displayName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DisplayNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$displayNameHash() => r'e414ac9e0b492472260d351a43f0018e1409bf0d';

/// The stored display name for [userId], or null if not set. Used by
/// chat's conversation list and conversation screen to show real
/// names instead of raw user ids.

final class DisplayNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  DisplayNameFamily._()
    : super(
        retry: null,
        name: r'displayNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The stored display name for [userId], or null if not set. Used by
  /// chat's conversation list and conversation screen to show real
  /// names instead of raw user ids.

  DisplayNameProvider call(String userId) =>
      DisplayNameProvider._(argument: userId, from: this);

  @override
  String toString() => r'displayNameProvider';
}
