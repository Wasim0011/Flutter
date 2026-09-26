// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caption_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether captions are currently shown. Call screens set an initial
/// default based on communicationPreference, but this is a plain
/// toggle from that point on — any user can turn captions on/off
/// regardless of their stated preference.

@ProviderFor(CaptionsEnabled)
final captionsEnabledProvider = CaptionsEnabledProvider._();

/// Whether captions are currently shown. Call screens set an initial
/// default based on communicationPreference, but this is a plain
/// toggle from that point on — any user can turn captions on/off
/// regardless of their stated preference.
final class CaptionsEnabledProvider
    extends $NotifierProvider<CaptionsEnabled, bool> {
  /// Whether captions are currently shown. Call screens set an initial
  /// default based on communicationPreference, but this is a plain
  /// toggle from that point on — any user can turn captions on/off
  /// regardless of their stated preference.
  CaptionsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captionsEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captionsEnabledHash();

  @$internal
  @override
  CaptionsEnabled create() => CaptionsEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$captionsEnabledHash() => r'89c2a90772250c3c13bc7f0e9b925a85a506b2ae';

/// Whether captions are currently shown. Call screens set an initial
/// default based on communicationPreference, but this is a plain
/// toggle from that point on — any user can turn captions on/off
/// regardless of their stated preference.

abstract class _$CaptionsEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Latest caption line per participant, keyed by participant identity.
/// Updated from both our own speech recognition and data messages
/// received from remote participants over the LiveKit room.

@ProviderFor(CaptionFeed)
final captionFeedProvider = CaptionFeedProvider._();

/// Latest caption line per participant, keyed by participant identity.
/// Updated from both our own speech recognition and data messages
/// received from remote participants over the LiveKit room.
final class CaptionFeedProvider
    extends $NotifierProvider<CaptionFeed, Map<String, CaptionLine>> {
  /// Latest caption line per participant, keyed by participant identity.
  /// Updated from both our own speech recognition and data messages
  /// received from remote participants over the LiveKit room.
  CaptionFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captionFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captionFeedHash();

  @$internal
  @override
  CaptionFeed create() => CaptionFeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, CaptionLine> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, CaptionLine>>(value),
    );
  }
}

String _$captionFeedHash() => r'1079efc4193eb3eb23209eacbf175eac7338c755';

/// Latest caption line per participant, keyed by participant identity.
/// Updated from both our own speech recognition and data messages
/// received from remote participants over the LiveKit room.

abstract class _$CaptionFeed extends $Notifier<Map<String, CaptionLine>> {
  Map<String, CaptionLine> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, CaptionLine>, Map<String, CaptionLine>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, CaptionLine>, Map<String, CaptionLine>>,
              Map<String, CaptionLine>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
