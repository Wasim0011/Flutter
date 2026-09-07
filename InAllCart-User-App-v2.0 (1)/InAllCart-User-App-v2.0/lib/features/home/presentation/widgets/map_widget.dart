import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../../../core/constants/app_constants.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../app_config/domain/entities/app_config.dart';

class MapWidget extends StatefulWidget {
  final MapProvider mapProvider;
  final String? googleMapsApiKey;
  final double? initialLat;
  final double? initialLng;
  final double initialZoom;
  final bool showUserLocation;
  final List<MapMarker>? markers;
  final Function(double lat, double lng)? onTap;

  const MapWidget({
    super.key,
    required this.mapProvider,
    this.googleMapsApiKey,
    this.initialLat,
    this.initialLng,
    this.initialZoom = 14.0,
    this.showUserLocation = true,
    this.markers,
    this.onTap,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  double? _currentLat;
  double? _currentLng;
  bool _isLoading = true;
  gmaps.GoogleMapController? _googleMapController;
  MapController? _osmMapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (widget.initialLat != null && widget.initialLng != null) {
      setState(() {
        _currentLat = widget.initialLat;
        _currentLng = widget.initialLng;
        _isLoading = false;
      });
      return;
    }

    try {
      final locationService = getIt<LocationService>();
      final position = await locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _isLoading = false;
        });
      } else {
        // Default to a fallback location
        setState(() {
          _currentLat = 28.6139; // Delhi
          _currentLng = 77.2090;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLat = 28.6139;
        _currentLng = 77.2090;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.mapProvider == MapProvider.google) {
      return _buildGoogleMap();
    } else {
      return _buildOSMMap();
    }
  }

  Widget _buildGoogleMap() {
    final markers = <gmaps.Marker>{};

    // Add user location marker
    if (widget.showUserLocation && _currentLat != null && _currentLng != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('user_location'),
          position: gmaps.LatLng(_currentLat!, _currentLng!),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    // Add custom markers
    if (widget.markers != null) {
      for (final marker in widget.markers!) {
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(marker.id),
            position: gmaps.LatLng(marker.lat, marker.lng),
            infoWindow: gmaps.InfoWindow(title: marker.title),
          ),
        );
      }
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(_currentLat!, _currentLng!),
        zoom: widget.initialZoom,
      ),
      markers: markers,
      myLocationEnabled: widget.showUserLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _googleMapController = controller;
      },
      onTap: widget.onTap != null
          ? (latLng) => widget.onTap!(latLng.latitude, latLng.longitude)
          : null,
    );
  }

  Widget _buildOSMMap() {
    final markers = <Marker>[];

    // Add user location marker
    if (widget.showUserLocation && _currentLat != null && _currentLng != null) {
      markers.add(
        Marker(
          point: LatLng(_currentLat!, _currentLng!),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Add custom markers
    if (widget.markers != null) {
      for (final marker in widget.markers!) {
        markers.add(
          Marker(
            point: LatLng(marker.lat, marker.lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: marker.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: marker.color ?? AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  marker.icon ?? Icons.store,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    return FlutterMap(
      mapController: _osmMapController,
      options: MapOptions(
        initialCenter: LatLng(_currentLat!, _currentLng!),
        initialZoom: widget.initialZoom,
        onTap: widget.onTap != null
            ? (tapPosition, point) => widget.onTap!(point.latitude, point.longitude)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: AppConstants.packageName,
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _osmMapController?.dispose();
    super.dispose();
  }
}

class MapMarker {
  final String id;
  final double lat;
  final double lng;
  final String? title;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const MapMarker({
    required this.id,
    required this.lat,
    required this.lng,
    this.title,
    this.icon,
    this.color,
    this.onTap,
  });
}
