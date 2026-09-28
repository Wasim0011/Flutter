// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(directory)
final directoryProvider = DirectoryProvider._();

final class DirectoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PublicProfile>>,
          List<PublicProfile>,
          Stream<List<PublicProfile>>
        >
    with
        $FutureModifier<List<PublicProfile>>,
        $StreamProvider<List<PublicProfile>> {
  DirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directoryHash();

  @$internal
  @override
  $StreamProviderElement<List<PublicProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PublicProfile>> create(Ref ref) {
    return directory(ref);
  }
}

String _$directoryHash() => r'0f7018ff3e207c608adbd896f7088a59f7e55255';

@ProviderFor(publicProfile)
final publicProfileProvider = PublicProfileFamily._();

final class PublicProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<PublicProfile?>,
          PublicProfile?,
          FutureOr<PublicProfile?>
        >
    with $FutureModifier<PublicProfile?>, $FutureProvider<PublicProfile?> {
  PublicProfileProvider._({
    required PublicProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'publicProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicProfileHash();

  @override
  String toString() {
    return r'publicProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PublicProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PublicProfile?> create(Ref ref) {
    final argument = this.argument as String;
    return publicProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicProfileHash() => r'49344d0d1fbcaaa830f2e9846838540a90a0d306';

final class PublicProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PublicProfile?>, String> {
  PublicProfileFamily._()
    : super(
        retry: null,
        name: r'publicProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PublicProfileProvider call(String userId) =>
      PublicProfileProvider._(argument: userId, from: this);

  @override
  String toString() => r'publicProfileProvider';
}
