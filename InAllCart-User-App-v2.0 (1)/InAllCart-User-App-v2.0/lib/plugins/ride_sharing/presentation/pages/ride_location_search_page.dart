import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../data/services/place_search_service.dart';

/// Uber-style location search page.
/// Shows both pickup and dropoff fields at the top.
/// The active field (pickup or dropoff) is highlighted.
/// Uses Google Places autocomplete when an API key is configured, falling
/// back to the platform geocoder; plus a map pin picker and current-location
/// shortcut.
class RideLocationSearchPage extends StatefulWidget {
  /// Which field is initially active: 'pickup' or 'dropoff'
  final String activeField;
  final LatLng? currentLocation;
  final String? initialPickupAddress;
  final String? initialDropoffAddress;

  const RideLocationSearchPage({
    super.key,
    this.activeField = 'dropoff',
    this.currentLocation,
    this.initialPickupAddress,
    this.initialDropoffAddress,
  });

  @override
  State<RideLocationSearchPage> createState() => _RideLocationSearchPageState();
}

class _RideLocationSearchPageState extends State<RideLocationSearchPage> {
  late String _activeField; // 'pickup' or 'dropoff'

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _dropoffFocus = FocusNode();

  List<_LocationSuggestion> _suggestions = [];
  bool _showMapPicker = false;
  bool _isSearching = false;
  Timer? _debounce;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  late final PlaceSearchService _placeService;

  // Resolved locations
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;

  @override
  void initState() {
    super.initState();
    _activeField = widget.activeField;
    _selectedLocation = widget.currentLocation;
    if (_selectedLocation == null) {
      _fetchLiveCurrentLocation();
    }

    // Build the place-search service with the configured Google key (if any).
    final configState = context.read<AppConfigBloc>().state;
    final apiKey = configState is AppConfigLoaded
        ? configState.config.googleMapsApiKey
        : null;
    _placeService = PlaceSearchService(googleApiKey: apiKey);
    _placeService.startSession(
        DateTime.now().microsecondsSinceEpoch.toString());

    // Pre-fill from parent
    if (widget.initialPickupAddress != null) {
      _pickupController.text = widget.initialPickupAddress!;
    }
    if (widget.initialDropoffAddress != null) {
      _dropoffController.text = widget.initialDropoffAddress!;
    }

    // Pickup defaults to the user's current location. If the parent didn't
    // pass a pickup address but we have current coordinates, seed the pickup
    // field and resolve a readable address in the background.
    if (widget.currentLocation != null) {
      _pickupLatLng = widget.currentLocation;
      if (_pickupController.text.trim().isEmpty) {
        _pickupController.text = 'Current Location';
        _resolveCurrentPickupAddress();
      }
    }

    // Dropoff ("Where to?") is the active field by default — focus it so the
    // marker/keyboard land there, not on the already-filled pickup.
    _activeField = widget.activeField == 'pickup' ? 'pickup' : 'dropoff';

    _loadSuggestions('');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeField == 'pickup') {
        _pickupFocus.requestFocus();
      } else {
        _dropoffFocus.requestFocus();
      }
    });

    _pickupFocus.addListener(() {
      if (_pickupFocus.hasFocus) {
        setState(() => _activeField = 'pickup');
        _loadSuggestions(_pickupController.text);
      }
    });
    _dropoffFocus.addListener(() {
      if (_dropoffFocus.hasFocus) {
        setState(() => _activeField = 'dropoff');
        _loadSuggestions(_dropoffController.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _placeService.endSession();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocus.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  /// Reverse-geocodes the current location into a readable pickup label,
  /// only overwriting the placeholder if the user hasn't typed/changed it.
  Future<void> _resolveCurrentPickupAddress() async {
    final loc = _selectedLocation ?? widget.currentLocation;
    if (loc == null) return;
    final label = await _placeService.reverseGeocode(loc);
    if (!mounted) return;
    if (_pickupController.text.trim().isEmpty ||
        _pickupController.text == 'Current Location') {
      setState(() => _pickupController.text = label);
    }
  }

  Future<void> _fetchLiveCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final loc = LatLng(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _selectedLocation = loc;
            _pickupLatLng = loc;
          });
          _resolveCurrentPickupAddress();
        }
      }
    } catch (_) {}
  }

  void _loadSuggestions(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _suggestions = [
          _LocationSuggestion(
            name: 'Current Location',
            address: 'Use your GPS location',
            location: widget.currentLocation,
            icon: Icons.my_location,
            isCurrentLocation: true,
          ),
        ];
      });
      return;
    }
    // Debounce typing, then run a real geocoder search.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _runGeocodeSearch(query.trim());
    });
  }

  Future<void> _runGeocodeSearch(String query) async {
    if (query.length < 3) {
      setState(() {
        _isSearching = false;
        _suggestions = const [];
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final predictions =
          await _placeService.autocomplete(query, near: widget.currentLocation);
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _suggestions = predictions
            .map((p) => _LocationSuggestion(
                  name: p.primaryText.isNotEmpty ? p.primaryText : p.fullText,
                  address: p.secondaryText,
                  location: p.latLng,
                  icon: Icons.location_on_outlined,
                  prediction: p,
                ))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _suggestions = const [];
      });
    }
  }

  void _onSearchChanged(String query) {
    _loadSuggestions(query);
  }

  Future<void> _selectSuggestion(_LocationSuggestion suggestion) async {
    // Resolve coordinates + label.
    LatLng? loc = suggestion.location;
    String label = suggestion.name;

    if (suggestion.isCurrentLocation) {
      loc = await _resolveCurrentLatLng();
      if (loc == null) return; // permission/service error already surfaced
      label = 'Current Location';
    } else if (suggestion.prediction != null && loc == null) {
      // Google prediction → resolve via Place Details.
      final resolved = await _placeService.resolve(suggestion.prediction!);
      if (resolved == null) {
        _showLocationError('Could not resolve that place. Try another.');
        return;
      }
      loc = resolved.latLng;
      label = suggestion.name.isNotEmpty ? suggestion.name : resolved.label;
    }
    if (loc == null) return;

    if (_activeField == 'pickup') {
      setState(() {
        _pickupController.text = label;
        _pickupLatLng = loc;
      });
      // Auto-switch to dropoff if empty
      if (_dropoffController.text.isEmpty) {
        _dropoffFocus.requestFocus();
      } else {
        _tryConfirm();
      }
    } else {
      setState(() {
        _dropoffController.text = label;
        _dropoffLatLng = loc;
      });
      _tryConfirm();
    }
  }

  /// Returns a live GPS fix (or the parent-provided current location as a
  /// fallback), handling permission/service checks.
  Future<LatLng?> _resolveCurrentLatLng() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (widget.currentLocation != null) return widget.currentLocation;
        _showLocationError('Location services are off. Please enable GPS.');
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (widget.currentLocation != null) return widget.currentLocation;
        _showLocationError('Location permission denied.');
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return widget.currentLocation;
    }
  }

  void _tryConfirm() {
    // If both are set, return result
    if (_pickupLatLng != null && _dropoffLatLng != null) {
      Navigator.pop(context, {
        'pickup_name': _pickupController.text,
        'pickup_location': _pickupLatLng,
        'dropoff_name': _dropoffController.text,
        'dropoff_location': _dropoffLatLng,
      });
    } else if (_activeField == 'dropoff' && _dropoffLatLng != null) {
      // Pickup defaults to current location
      Navigator.pop(context, {
        'pickup_name': _pickupController.text.isNotEmpty
            ? _pickupController.text
            : 'Current Location',
        'pickup_location': widget.currentLocation,
        'dropoff_name': _dropoffController.text,
        'dropoff_location': _dropoffLatLng,
      });
    }
  }

  void _openMapPicker() {
    setState(() => _showMapPicker = true);
  }

  /// Resolves the device's current location for the map picker, handling
  /// location-service and permission checks. Centres the map on success and
  /// surfaces a message on failure (previously this failed silently).
  Future<void> _goToMyLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are off. Please enable GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showLocationError('Location permission denied.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
          'Location permission permanently denied. Enable it in Settings.',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _selectedLocation = loc);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(loc, 16.0),
      );
    } catch (e) {
      _showLocationError('Could not get your location. Please try again.');
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmMapLocation() async {
    final picked = _selectedLocation;
    if (picked == null) return;

    // Reverse-geocode the picked point into a readable address.
    final label = await _addressForLatLng(picked);

    if (!mounted) return;
    if (_activeField == 'pickup') {
      setState(() {
        _pickupController.text = label;
        _pickupLatLng = picked;
        _showMapPicker = false;
      });
      if (_dropoffController.text.isEmpty) {
        _dropoffFocus.requestFocus();
      } else {
        _tryConfirm();
      }
    } else {
      setState(() {
        _dropoffController.text = label;
        _dropoffLatLng = picked;
        _showMapPicker = false;
      });
      _tryConfirm();
    }
  }

  /// Reverse-geocodes [point] into a human-readable address.
  Future<String> _addressForLatLng(LatLng point) {
    return _placeService.reverseGeocode(point);
  }

  void _swapLocations() {
    setState(() {
      final tmpText = _pickupController.text;
      final tmpLatLng = _pickupLatLng;
      _pickupController.text = _dropoffController.text;
      _pickupLatLng = _dropoffLatLng;
      _dropoffController.text = tmpText;
      _dropoffLatLng = tmpLatLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMapPicker) return _buildMapPicker();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Top bar with both fields ──────────────────────────────────
          _buildTopBar(context),

          // ── Suggestions ──────────────────────────────────────────────
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: _suggestions.length + 1, // +1 for "Set on map"
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSetOnMapTile();
                }
                return _buildSuggestionTile(_suggestions[index - 1]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(top: 12, right: 12),
              child: Icon(Icons.arrow_back, color: Colors.black87, size: 24),
            ),
          ),

          // Pickup + Dropoff fields with connector line
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Dot indicators + connector
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _activeField == 'pickup'
                            ? Colors.black87
                            : Colors.grey[400],
                        border: Border.all(
                          color: _activeField == 'pickup'
                              ? Colors.black87
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 1.5,
                      height: 28,
                      color: Colors.grey[300],
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(2),
                        color: _activeField == 'dropoff'
                            ? Colors.black87
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Text fields
                Expanded(
                  child: Column(
                    children: [
                      // Pickup field
                      GestureDetector(
                        onTap: () {
                          setState(() => _activeField = 'pickup');
                          _pickupFocus.requestFocus();
                        },
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _activeField == 'pickup'
                                ? Colors.grey[100]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _activeField == 'pickup'
                                  ? Colors.black87
                                  : Colors.grey[200]!,
                              width: _activeField == 'pickup' ? 1.5 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _pickupController,
                            focusNode: _pickupFocus,
                            onChanged: _onSearchChanged,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Pickup location',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isCollapsed: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              suffixIconConstraints: const BoxConstraints(
                                  minWidth: 24, minHeight: 24),
                              suffixIcon: _pickupController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _pickupController.clear();
                                        _pickupLatLng = null;
                                        _loadSuggestions('');
                                      },
                                      child: const Icon(Icons.close,
                                          size: 16, color: Colors.grey),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Dropoff field
                      GestureDetector(
                        onTap: () {
                          setState(() => _activeField = 'dropoff');
                          _dropoffFocus.requestFocus();
                        },
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _activeField == 'dropoff'
                                ? Colors.grey[100]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _activeField == 'dropoff'
                                  ? Colors.black87
                                  : Colors.grey[200]!,
                              width: _activeField == 'dropoff' ? 1.5 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _dropoffController,
                            focusNode: _dropoffFocus,
                            onChanged: _onSearchChanged,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Where to?',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isCollapsed: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              suffixIconConstraints: const BoxConstraints(
                                  minWidth: 24, minHeight: 24),
                              suffixIcon: _dropoffController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _dropoffController.clear();
                                        _dropoffLatLng = null;
                                        _loadSuggestions('');
                                      },
                                      child: const Icon(Icons.close,
                                          size: 16, color: Colors.grey),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Swap button
          GestureDetector(
            onTap: _swapLocations,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_vert,
                    size: 20, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Set on map tile ──────────────────────────────────────────────────

  Widget _buildSetOnMapTile() {
    return InkWell(
      onTap: _openMapPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.map_outlined,
                  color: Colors.black87, size: 22),
            ),
            const SizedBox(width: 14),
            const Text(
              'Set location on map',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Suggestion tile ──────────────────────────────────────────────────

  Widget _buildSuggestionTile(_LocationSuggestion suggestion) {
    final isCurrentLocation = suggestion.isCurrentLocation;
    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCurrentLocation
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                suggestion.icon,
                color: isCurrentLocation ? Colors.blue : Colors.black54,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isCurrentLocation
                          ? Colors.blue
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.address,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map picker ───────────────────────────────────────────────────────

  Widget _buildMapPicker() {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation!,
              zoom: 16.0,
            ),
            onMapCreated: (c) => _mapController = c,
            onCameraMove: (pos) =>
                setState(() => _selectedLocation = pos.target),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            buildingsEnabled: false,
          ),

          // Center pin — shadow + pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 52,
                  color: _activeField == 'pickup'
                      ? Colors.green[700]
                      : Colors.red[700],
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 52),
              ],
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 12,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () =>
                        setState(() => _showMapPicker = false),
                  ),
                  Expanded(
                    child: Text(
                      _activeField == 'pickup'
                          ? 'Set pickup location'
                          : 'Set drop-off location',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _goToMyLocation,
                    child: const Text('My location',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          // Bottom confirm
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _activeField == 'pickup'
                            ? Icons.trip_origin
                            : Icons.location_on,
                        color: _activeField == 'pickup'
                            ? Colors.green[700]
                            : Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLocation != null
                              ? 'Lat ${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                                  'Lng ${_selectedLocation!.longitude.toStringAsFixed(5)}'
                              : 'Move map to select',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirmMapLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Confirm ${_activeField == 'pickup' ? 'Pickup' : 'Drop-off'}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // My location FAB
          Positioned(
            bottom: 130,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _goToMyLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.my_location,
                  color: Colors.black87, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSuggestion {
  final String name;
  final String address;
  final LatLng? location;
  final IconData icon;
  final bool isCurrentLocation;
  final PlacePrediction? prediction;

  _LocationSuggestion({
    required this.name,
    required this.address,
    required this.location,
    required this.icon,
    this.isCurrentLocation = false,
    this.prediction,
  });
}
