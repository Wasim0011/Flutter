import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../app_config/domain/entities/app_config.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';

class LocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  double _selectedLat = 28.6139;
  double _selectedLng = 77.2090;
  String _address = 'Getting your location...';
  bool _isLoading = true;
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Location> _searchResults = [];
  bool _isOutOfZone = false;
  
  gmaps.GoogleMapController? _googleMapController;
  final MapController _osmMapController = MapController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _checkZone() {
    final distance = Geolocator.distanceBetween(
      _selectedLat,
      _selectedLng,
      AppConstants.serviceLat,
      AppConstants.serviceLng,
    );
    
    if (mounted) {
      setState(() {
        _isOutOfZone = distance > AppConstants.serviceRadius;
      });
    }
  }

  Future<void> _initLocation() async {
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLat = widget.initialLat!;
      _selectedLng = widget.initialLng!;
    } else {
      await _getCurrentLocation();
    }
    await _getAddressFromCoordinates();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationService = getIt<LocationService>();
      final result = await locationService.getCurrentLocationWithStatus();
      
      if (result.status == LocationStatus.granted && result.position != null) {
        _selectedLat = result.position!.latitude;
        _selectedLng = result.position!.longitude;
      } else if (result.status == LocationStatus.serviceDisabled) {
        // Location service check can be flaky — try last known position first
        try {
          final lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            _selectedLat = lastPosition.latitude;
            _selectedLng = lastPosition.longitude;
            return;
          }
        } catch (e) {
          // Non-critical: last known position unavailable. Fall through to show dialog.
        }
        
        if (mounted) {
          _showLocationDialog(result.status);
        }
      } else {
        if (mounted) {
          _showLocationDialog(result.status);
        }
      }
    } catch (e) {
      // location failed
    }
  }

  void _showLocationDialog(LocationStatus status) {
    String title;
    String message;
    String buttonText;
    VoidCallback onPressed;

    switch (status) {
      case LocationStatus.serviceDisabled:
        title = 'Location Services Disabled';
        message = 'Please enable location services on your device to use this feature.';
        buttonText = 'Open Settings';
        onPressed = () async {
          Navigator.pop(context);
          await Geolocator.openLocationSettings();
        };
        break;
      case LocationStatus.denied:
        title = 'Location Permission Required';
        message = 'We need location permission to show your current location on the map.';
        buttonText = 'Grant Permission';
        onPressed = () async {
          Navigator.pop(context);
          final granted = await Permission.location.request();
          if (granted.isGranted) {
            _onMyLocationPressed();
          }
        };
        break;
      case LocationStatus.deniedForever:
        title = 'Location Permission Denied';
        message = 'Location permission is permanently denied. Please enable it from app settings.';
        buttonText = 'Open App Settings';
        onPressed = () async {
          Navigator.pop(context);
          await openAppSettings();
        };
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onPressed,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Future<void> _getAddressFromCoordinates() async {
    _checkZone();
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(_selectedLat, _selectedLng);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).toList();
        setState(() => _address = parts.isNotEmpty ? parts.join(', ') : 'Location selected');
      }
    } catch (e) {
      if (mounted) setState(() => _address = 'Location selected');
    }
    if (mounted) setState(() => _isLoadingAddress = false);
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      if (mounted) {
        setState(() {
          _searchResults = locations;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find "$query"')),
        );
      }
    }
  }

  void _selectSearchResult(Location location) async {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _selectedLat = location.latitude;
      _selectedLng = location.longitude;
      _searchResults = [];
    });
    await _getAddressFromCoordinates();
    _animateToLocation();
  }

  void _animateToLocation() {
    if (_googleMapController != null) {
      _googleMapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(_selectedLat, _selectedLng),
          16,
        ),
      );
    }
    if (_mapReady) {
      _osmMapController.move(LatLng(_selectedLat, _selectedLng), 16);
    }
  }

  void _onMyLocationPressed() async {
    setState(() => _isLoadingAddress = true);
    await _getCurrentLocation();
    await _getAddressFromCoordinates();
    _animateToLocation();
  }

  void _confirmLocation() {
    context.pop({
      'lat': _selectedLat,
      'lng': _selectedLng,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(
        title: 'Select Location',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    // Map
                    Expanded(
                      child: BlocBuilder<AppConfigBloc, AppConfigState>(
                        builder: (context, state) {
                          final mapProvider = state is AppConfigLoaded
                              ? state.config.mapProvider
                              : MapProvider.osm;

                          return Stack(
                            children: [
                              mapProvider == MapProvider.google
                                  ? _buildGoogleMap()
                                  : _buildOSMMap(),
                              // Center pin
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_pin,
                                      size: 50,
                                      color: AppColors.primary,
                                    ),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // My location button
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: FloatingActionButton.small(
                                  heroTag: 'my_location',
                                  onPressed: _onMyLocationPressed,
                                  backgroundColor: Colors.white,
                                  child: const Icon(Icons.my_location, color: AppColors.primary),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Bottom panel
                    _buildBottomPanel(),
                  ],
                ),
                // Search overlay
                _buildSearchOverlay(),
              ],
            ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for a location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length > 2) {
                  _searchLocation(value);
                }
              },
              onSubmitted: _searchLocation,
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (_searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final loc = _searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: FutureBuilder<List<Placemark>>(
                        future: placemarkFromCoordinates(loc.latitude, loc.longitude),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final place = snapshot.data!.first;
                            final parts = [
                              place.street,
                              place.locality,
                              place.administrativeArea,
                            ].where((e) => e != null && e.isNotEmpty).toList();
                            return Text(
                              parts.join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return Text('${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}');
                        },
                      ),
                      onTap: () => _selectSearchResult(loc),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Location',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      _isLoadingAddress
                          ? const Text('Finding address...', style: TextStyle(fontWeight: FontWeight.w500))
                          : Text(
                              _address,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isOutOfZone)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Out of Zone: We don\'t deliver here yet.',
                        style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: _isOutOfZone ? null : _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOutOfZone ? Colors.grey : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isOutOfZone ? 'Out of Zone' : 'Confirm Location',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(_selectedLat, _selectedLng),
        zoom: 16,
      ),
      onMapCreated: (controller) {
        _googleMapController = controller;
      },
      onCameraMove: (position) {
        _selectedLat = position.target.latitude;
        _selectedLng = position.target.longitude;
      },
      onCameraIdle: _getAddressFromCoordinates,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      circles: {
        gmaps.Circle(
          circleId: const gmaps.CircleId('service_area'),
          center: gmaps.LatLng(AppConstants.serviceLat, AppConstants.serviceLng),
          radius: AppConstants.serviceRadius,
          fillColor: AppColors.primary.withValues(alpha: 0.1),
          strokeColor: AppColors.primary.withValues(alpha: 0.3),
          strokeWidth: 2,
        ),
      },
    );
  }

  Widget _buildOSMMap() {
    return FlutterMap(
      mapController: _osmMapController,
      options: MapOptions(
        initialCenter: LatLng(_selectedLat, _selectedLng),
        initialZoom: 16,
        onMapReady: () {
          _mapReady = true;
        },
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            _selectedLat = position.center.latitude;
            _selectedLng = position.center.longitude;
          }
        },
        onMapEvent: (event) {
          if (event is MapEventMoveEnd) {
            _selectedLat = event.camera.center.latitude;
            _selectedLng = event.camera.center.longitude;
            _getAddressFromCoordinates();
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: AppConstants.packageName,
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: LatLng(AppConstants.serviceLat, AppConstants.serviceLng),
              radius: AppConstants.serviceRadius,
              useRadiusInMeter: true,
              color: AppColors.primary.withValues(alpha: 0.1),
              borderColor: AppColors.primary.withValues(alpha: 0.3),
              borderStrokeWidth: 2,
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _googleMapController?.dispose();
    _osmMapController.dispose();
    super.dispose();
  }
}
