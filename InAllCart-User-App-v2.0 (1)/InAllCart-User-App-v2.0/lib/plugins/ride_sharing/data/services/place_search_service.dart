import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;

/// A single place prediction shown in the search list.
class PlacePrediction {
  final String primaryText; // e.g. "Connaught Place"
  final String secondaryText; // e.g. "New Delhi, India"

  /// Google place id (null for geocoder-fallback results, which carry [latLng]).
  final String? placeId;

  /// Coordinates — present immediately for geocoder results; resolved on
  /// selection for Google predictions.
  final LatLng? latLng;

  const PlacePrediction({
    required this.primaryText,
    required this.secondaryText,
    this.placeId,
    this.latLng,
  });

  String get fullText =>
      secondaryText.isEmpty ? primaryText : '$primaryText, $secondaryText';
}

/// A resolved place (coordinates + display label).
class ResolvedPlace {
  final LatLng latLng;
  final String label;
  const ResolvedPlace(this.latLng, this.label);
}

/// Place search backed by Google Places when an API key is configured,
/// with an automatic fallback to the platform geocoder otherwise.
class PlaceSearchService {
  final String? googleApiKey;
  final http.Client _client;

  PlaceSearchService({this.googleApiKey, http.Client? client})
      : _client = client ?? http.Client();

  bool get _hasGoogle => googleApiKey != null && googleApiKey!.trim().isNotEmpty;

  /// Session token improves Autocomplete billing/quality; rotate per session.
  String? _sessionToken;
  void startSession(String token) => _sessionToken = token;
  void endSession() => _sessionToken = null;

  /// Returns predictions for [query]. Biases results around [near] when given.
  Future<List<PlacePrediction>> autocomplete(
    String query, {
    LatLng? near,
  }) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    if (_hasGoogle) {
      try {
        final results = await _googleAutocomplete(q, near: near);
        // If Google returns nothing (e.g. key/referrer issue), fall back.
        if (results.isNotEmpty) return results;
      } catch (_) {
        // Network/parse error → fall back to the platform geocoder.
      }
    }
    return _geocoderSearch(q);
  }

  /// Resolves a prediction to coordinates + a display label.
  /// Google predictions need a Place Details call; geocoder results already
  /// carry their coordinates.
  Future<ResolvedPlace?> resolve(PlacePrediction prediction) async {
    if (prediction.latLng != null) {
      return ResolvedPlace(prediction.latLng!, prediction.fullText);
    }
    if (_hasGoogle && prediction.placeId != null) {
      try {
        final place = await _googlePlaceDetails(prediction.placeId!);
        if (place != null) return place;
      } catch (_) {
        // fall through
      }
    }
    // Last resort: geocode the prediction text.
    try {
      final locs = await geo.locationFromAddress(prediction.fullText);
      if (locs.isNotEmpty) {
        return ResolvedPlace(
          LatLng(locs.first.latitude, locs.first.longitude),
          prediction.fullText,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Reverse-geocodes a coordinate into a readable address.
  Future<String> reverseGeocode(LatLng point) async {
    try {
      final marks =
          await geo.placemarkFromCoordinates(point.latitude, point.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = <String>[
          if ((p.name ?? '').isNotEmpty) p.name!,
          if ((p.street ?? '').isNotEmpty && p.street != p.name) p.street!,
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
        ];
        final seen = <String>{};
        final unique = parts.where(seen.add).take(3).toList();
        if (unique.isNotEmpty) return unique.join(', ');
      }
    } catch (_) {}
    return '${point.latitude.toStringAsFixed(5)}, '
        '${point.longitude.toStringAsFixed(5)}';
  }

  // ── Google Places ──────────────────────────────────────────────────────

  Future<List<PlacePrediction>> _googleAutocomplete(
    String query, {
    LatLng? near,
  }) async {
    final params = <String, String>{
      'input': query,
      'key': googleApiKey!,
      if (_sessionToken != null) 'sessiontoken': _sessionToken!,
      if (near != null) 'location': '${near.latitude},${near.longitude}',
      if (near != null) 'radius': '50000',
    };
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );
    final resp = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return const [];
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final status = data['status'] as String?;
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      // REQUEST_DENIED / INVALID_REQUEST etc. → signal caller to fall back.
      throw Exception('Places autocomplete status: $status');
    }
    final preds = (data['predictions'] as List?) ?? const [];
    return preds.map((p) {
      final m = p as Map<String, dynamic>;
      final sf = m['structured_formatting'] as Map<String, dynamic>?;
      return PlacePrediction(
        primaryText: sf?['main_text'] as String? ??
            m['description'] as String? ??
            '',
        secondaryText: sf?['secondary_text'] as String? ?? '',
        placeId: m['place_id'] as String?,
      );
    }).toList();
  }

  Future<ResolvedPlace?> _googlePlaceDetails(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'key': googleApiKey!,
        'fields': 'geometry,name,formatted_address',
        if (_sessionToken != null) 'sessiontoken': _sessionToken!,
      },
    );
    final resp = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;
    final result = data['result'] as Map<String, dynamic>?;
    final loc = result?['geometry']?['location'] as Map<String, dynamic>?;
    if (loc == null) return null;
    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();
    final label = (result?['name'] as String?) ??
        (result?['formatted_address'] as String?) ??
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    return ResolvedPlace(LatLng(lat, lng), label);
  }

  // ── Geocoder fallback ────────────────────────────────────────────────────

  Future<List<PlacePrediction>> _geocoderSearch(String query) async {
    try {
      final locs = await geo.locationFromAddress(query);
      final out = <PlacePrediction>[];
      for (final loc in locs.take(6)) {
        final latLng = LatLng(loc.latitude, loc.longitude);
        String primary = query;
        String secondary = '';
        try {
          final marks =
              await geo.placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (marks.isNotEmpty) {
            final p = marks.first;
            primary = [p.name, p.street, p.locality]
                    .where((e) => e != null && e.isNotEmpty)
                    .cast<String>()
                    .firstOrNull ??
                query;
            secondary = [p.subLocality, p.locality, p.administrativeArea, p.country]
                .where((e) => e != null && e.isNotEmpty && e != primary)
                .cast<String>()
                .toSet()
                .join(', ');
          }
        } catch (_) {}
        out.add(PlacePrediction(
          primaryText: primary,
          secondaryText: secondary,
          latLng: latLng,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}
