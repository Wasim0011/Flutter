import 'dart:async';
import 'package:media_kit/media_kit.dart';
// NativePlayer.setProperty has no public equivalent; needed to disable the mpv
// audio output driver on Android.
// ignore: implementation_imports
import 'package:media_kit/src/player/native/player/player.dart' as native_player;
import 'package:media_kit_video/media_kit_video.dart';

/// Manages video playback for the app.
///
/// Two separate pools:
///
/// 1. Header pool (priority 2): a single persistent Player+VideoController
///    that is NEVER disposed — only the media source is swapped via
///    player.open(). This avoids Android ImageReader surface teardown/
///    recreation which causes MediaCodec::reclaim and buffer overflow.
///
/// 2. Content pool (priority 0/1): blocked entirely while header is active.
///    Content widgets gracefully degrade (show nothing) when blocked.
///
/// Priority: 0 = poster-frame only (never plays)
///           1 = default content video
///           2 = hero header video (persistent, always wins)
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // ── Header pool ────────────────────────────────────────────────────────────
  Player? _headerPlayer;
  VideoController? _headerController;
  String? _headerUrl;

  // True while _swapHeaderMedia is in-flight.
  bool _headerSwapping = false;
  // If resumeController is called while a swap is in-flight, we honour it
  // after open() completes instead of firing play() on an empty player.
  bool _headerPlayPending = false;

  // ── Content pool ──────────────────────────────────────────────────────────
  final Map<String, VideoEntry> _entries = {};
  final Map<String, int> _referenceCount = {};
  final Map<String, int> _priority = {};
  final Set<String> _widgetPaused = {};
  final List<String> _lruCache = [];

  static const int _maxContentPlayers = 1;
  static const int _maxCached = 1;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Pre-initialise the header player eagerly (call from main.dart before
  /// any widgets mount). Ensures [_headerPlayer] is non-null so the content
  /// pool guard blocks content players from the very first frame.
  void initHeaderPlayer() {
    if (_headerPlayer != null) return;
    _buildHeaderPlayer();
  }
  /// Priority 2 → header pool (persistent player, media-swap only).
  /// Priority 0/1 → content pool (blocked while header is active).
  VideoEntry? createController(String url, {int priority = 1}) {
    if (priority == 2) return _createHeaderController(url);
    return _createContentController(url, priority: priority);
  }

  /// Start playback for [url].
  void resumeController(String url) {
    if (_headerUrl == url) {
      if (_headerSwapping) {
        // open() hasn't completed yet — mark play as pending so
        // _swapHeaderMedia will call play() once open() finishes.
        _headerPlayPending = true;
      } else {
        _headerPlayer?.setPlaylistMode(PlaylistMode.loop);
        _headerPlayer?.play();
      }
      return;
    }
    _resumeContentController(url);
  }

  /// Pause without releasing.
  void pauseController(String url) {
    if (_headerUrl == url) {
      _headerPlayPending = false;
      _headerPlayer?.pause();
      return;
    }
    if (!_entries.containsKey(url)) return;
    _widgetPaused.add(url);
    _entries[url]!.player.pause();
  }

  /// Release. For header (priority 2), just pauses — never disposes.
  void releaseController(String url, {bool keepAlive = true}) {
    if (_headerUrl == url) {
      _headerPlayPending = false;
      _headerPlayer?.pause();
      return;
    }
    _releaseContentController(url, keepAlive: keepAlive);
  }

  /// Fully dispose everything. Call only on app exit.
  void clearAll() {
    _headerPlayer?.dispose();
    _headerPlayer = null;
    _headerController = null;
    _headerUrl = null;
    _headerSwapping = false;
    _headerPlayPending = false;
    for (final url in _entries.keys.toList()) {
      _disposeContentEntry(url);
    }
    _referenceCount.clear();
    _priority.clear();
    _widgetPaused.clear();
    _lruCache.clear();
  }

  // ── Header pool ────────────────────────────────────────────────────────────

  void _buildHeaderPlayer() {
    _headerPlayer = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 8 * 1024 * 1024,
        logLevel: MPVLogLevel.warn,
      ),
    );
    _headerController = VideoController(
      _headerPlayer!,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );
    _headerPlayer!.setVolume(0);
    // Disable audio output driver at the mpv level to prevent OpenSL ES from
    // allocating AudioTrack objects on every open() call ("Too many objects").
    // setProperty is on NativePlayer (internal), not the public Player API.
    final p = _headerPlayer!.platform;
    if (p is native_player.NativePlayer) {
      p.setProperty('ao', 'null');
    }
  }

  VideoEntry _createHeaderController(String url) {
    if (_headerPlayer == null) _buildHeaderPlayer();

    if (_headerUrl != url) {
      _headerUrl = url;
      _headerPlayPending = false;
      _swapHeaderMedia(url);
    }

    return VideoEntry(player: _headerPlayer!, controller: _headerController!);
  }

  Future<void> _swapHeaderMedia(String url) async {
    if (_headerSwapping) return;
    _headerSwapping = true;
    try {
      final player = _headerPlayer;
      if (player == null) return;

      // Pause the current decode pipeline before opening new media.
      // This prevents libmpv from briefly running two decoders on the same
      // ImageReader surface, which causes buffer overflow warnings.
      player.pause();

      // Wait one raster frame (≈16ms) for libmpv to process the pause
      // before issuing open(). stream.playing is unreliable here because
      // the player may already be paused (playing == false from the start).
      await Future<void>.delayed(const Duration(milliseconds: 16));

      // Bail if the url changed while we were waiting (rapid tab switches).
      if (_headerUrl != url || _headerPlayer == null) return;

      await player.open(Media(url), play: false);

      // If resumeController was called while we were swapping, honour it now.
      if (_headerPlayPending && _headerUrl == url) {
        _headerPlayPending = false;
        player.setPlaylistMode(PlaylistMode.loop);
        player.play();
      }
    } finally {
      _headerSwapping = false;
    }
  }

  // ── Content pool ───────────────────────────────────────────────────────────

  VideoEntry? _createContentController(String url, {int priority = 1}) {
    // Block content players while header is active — two simultaneous
    // VideoControllers on Android = two ImageReader surfaces = buffer overflow.
    if (_headerUrl != null) return null;

    if (_entries.containsKey(url)) {
      _incrementRef(url);
      _priority[url] = priority;
      return _entries[url];
    }

    if (_entries.length >= _maxContentPlayers) {
      if (_lruCache.isNotEmpty) _disposeContentEntry(_lruCache.removeAt(0));
      if (_entries.length >= _maxContentPlayers) return null;
    }

    final player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 4 * 1024 * 1024,
      ),
    );
    final controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    player.setVolume(0);
    player.open(Media(url), play: false);

    _entries[url] = VideoEntry(player: player, controller: controller);
    _referenceCount[url] = 1;
    _priority[url] = priority;
    _widgetPaused.add(url);

    return _entries[url];
  }

  void _resumeContentController(String url) {
    if (!_entries.containsKey(url)) return;
    _widgetPaused.remove(url);
    if ((_priority[url] ?? 1) == 0) return;
    final entry = _entries[url];
    if (entry == null) return;
    entry.player.setPlaylistMode(PlaylistMode.loop);
    entry.player.play();
  }

  void _releaseContentController(String url, {bool keepAlive = true}) {
    if (!_referenceCount.containsKey(url)) return;
    final newCount = (_referenceCount[url]! - 1).clamp(0, 999);
    _referenceCount[url] = newCount;
    if (newCount <= 0) {
      _widgetPaused.remove(url);
      final entry = _entries[url];
      if (!keepAlive || entry == null) {
        _disposeContentEntry(url);
      } else {
        entry.player.pause();
        if (!_lruCache.contains(url)) _lruCache.add(url);
        _trimCache();
      }
    }
  }

  void _incrementRef(String url) {
    if (_entries.containsKey(url)) {
      _referenceCount[url] = (_referenceCount[url] ?? 0) + 1;
      _lruCache.remove(url);
    }
  }

  void _trimCache() {
    while (_lruCache.length > _maxCached) {
      _disposeContentEntry(_lruCache.removeAt(0));
    }
  }

  void _disposeContentEntry(String url) {
    _entries[url]?.player.dispose();
    _entries.remove(url);
    _referenceCount.remove(url);
    _priority.remove(url);
    _widgetPaused.remove(url);
    _lruCache.remove(url);
  }
}

/// Holds a [Player] and its associated [VideoController].
class VideoEntry {
  final Player player;
  final VideoController controller;
  VideoEntry({required this.player, required this.controller});
}
