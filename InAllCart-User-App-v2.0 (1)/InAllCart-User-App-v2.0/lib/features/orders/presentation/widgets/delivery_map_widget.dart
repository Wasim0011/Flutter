import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../app_config/domain/entities/app_config.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../domain/entities/delivery_tracking.dart';

/// Professional Premium-level map widget with smooth animations
/// 
/// Features:
/// - Supports both Google Maps and OpenStreetMap (admin config)
/// - Animated marker movement (lerp interpolation)
/// - Custom markers (store, partner, destination)
/// - Route polyline with gradient
/// - Auto-zoom to fit all markers
/// - Smooth camera transitions
class DeliveryMapWidget extends StatefulWidget {
  final DeliveryTracking tracking;
  final List<TrackingHistoryPoint>? history;

  const DeliveryMapWidget({
    super.key,
    required this.tracking,
    this.history,
  });

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

class _DeliveryMapWidgetState extends State<DeliveryMapWidget>
    with SingleTickerProviderStateMixin {
  gmaps.GoogleMapController? _googleMapController;
  MapController? _osmMapController;
  late AnimationController _markerAnimationController;
  LatLng? _previousPartnerLocation;
  LatLng? _animatedPartnerLocation;

  // Google Maps specific
  Set<gmaps.Marker> _googleMarkers = {};
  Set<gmaps.Polyline> _googlePolylines = {};

  // OSM specific
  List<Marker> _osmMarkers = [];
  List<Polyline> _osmPolylines = [];
  
  // Route polyline points (actual road routes)
  List<gmaps.LatLng> _routePoints = [];
  List<LatLng> _osmRoutePoints = [];
  bool _isLoadingRoute = false;
  
  // User's current location from device
  Position? _userCurrentLocation;
  bool _hasAutoZoomed = false; // Prevent repeated auto-zoom

  @override
  void initState() {
    super.initState();

    // Animation controller for smooth marker movement
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _osmMapController = MapController();
    
    // Get user's real-time location from device
    _getUserLocation();
    
    _initializeMap();
  }
  
  /// Get user's current location from device (like Swiggy)
  Future<void> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _userCurrentLocation = position;
      });
      
      // Update markers with user location
      _updateMarkers();
      
      // Fit bounds to show both store and user location
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!_hasAutoZoomed) {
          _fitOSMMapBounds();
          _hasAutoZoomed = true;
        }
      });
      
      // Fetch route now that we have user location
      _fetchRoutePolyline();
      
    } catch (e) {
      // location failed
    }
  }

  @override
  void didUpdateWidget(DeliveryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate marker when location changes
    if (widget.tracking.currentLocation != null &&
        oldWidget.tracking.currentLocation != null) {
      final newLocation = LatLng(
        widget.tracking.currentLocation!.latitude,
        widget.tracking.currentLocation!.longitude,
      );
      final oldLocation = LatLng(
        oldWidget.tracking.currentLocation!.latitude,
        oldWidget.tracking.currentLocation!.longitude,
      );

      if (newLocation != oldLocation) {
        _animateMarkerMovement(oldLocation, newLocation);
        // Refetch route with new location
        _fetchRoutePolyline();
      }
    } else {
      _updateMarkers();
    }
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _googleMapController?.dispose();
    _osmMapController?.dispose();
    super.dispose();
  }

  void _initializeMap() {
    _updateMarkers();
    _fetchRoutePolyline();
  }

  /// Fetch actual road route using OSRM (free) or Google Directions API
  Future<void> _fetchRoutePolyline() async {
    if (_isLoadingRoute) return;
    
    // Only fetch if delivery partner is assigned and we have user location
    if (widget.tracking.deliveryPartner == null) {
      return;
    }

    // Need either user's device location or destination coordinates
    double? userLat;
    double? userLng;
    
    // Prefer user's real-time device location
    if (_userCurrentLocation != null) {
      userLat = _userCurrentLocation!.latitude;
      userLng = _userCurrentLocation!.longitude;
    } 
    // Fallback to destination address coordinates
    else if (widget.tracking.destination.latitude != null &&
        widget.tracking.destination.longitude != null) {
      userLat = widget.tracking.destination.latitude;
      userLng = widget.tracking.destination.longitude;
    }
    
    // If no user location available, don't fetch route
    if (userLat == null || userLng == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final currentLoc = widget.tracking.currentLocation;
      
      if (currentLoc != null) {
        // Route from delivery partner's current location to user's location
        await _fetchRoute(
          currentLoc.latitude,
          currentLoc.longitude,
          userLat,
          userLng,
        );
      } else if (widget.tracking.store != null) {
        // Route from store to user (delivery partner assigned but not started)
        await _fetchRoute(
          widget.tracking.store!.latitude,
          widget.tracking.store!.longitude,
          userLat,
          userLng,
        );
      }
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  /// Fetch route using OSRM (OpenStreetMap Routing Machine) - FREE
  Future<void> _fetchRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      // Using OSRM public API (FREE, no API key needed)
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '$startLng,$startLat;$endLng,$endLat'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          // Convert to LatLng points
          final googlePoints = <gmaps.LatLng>[];
          final osmPoints = <LatLng>[];

          for (var coord in coordinates) {
            final lng = coord[0] as double;
            final lat = coord[1] as double;
            googlePoints.add(gmaps.LatLng(lat, lng));
            osmPoints.add(LatLng(lat, lng));
          }

          setState(() {
            _routePoints = googlePoints;
            _osmRoutePoints = osmPoints;
            _updatePolylines();
          });
        }
      }
    } catch (e) {
      // Fallback to straight line
      _useStraightLineRoute(startLat, startLng, endLat, endLng);
    }
  }

  /// Fallback to straight line if route API fails
  void _useStraightLineRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    setState(() {
      _routePoints = [
        gmaps.LatLng(startLat, startLng),
        gmaps.LatLng(endLat, endLng),
      ];
      _osmRoutePoints = [
        LatLng(startLat, startLng),
        LatLng(endLat, endLng),
      ];
      _updatePolylines();
    });
  }

  void _updatePolylines() {
    _updateGooglePolylines();
    _updateOSMPolylines();
  }

  /// Animate marker movement with lerp interpolation (Premium-style)
  void _animateMarkerMovement(LatLng from, LatLng to) {
    _previousPartnerLocation = from;
    _markerAnimationController.reset();

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _markerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    animation.addListener(() {
      final lat = _lerpDouble(from.latitude, to.latitude, animation.value);
      final lng = _lerpDouble(from.longitude, to.longitude, animation.value);

      setState(() {
        _animatedPartnerLocation = LatLng(lat, lng);
        _updateMarkers();
      });
    });

    _markerAnimationController.forward();
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Calculate distance between two points in kilometers (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  void _updateMarkers() {
    _updateGoogleMarkers();
    _updateOSMMarkers();
  }

  void _updateGoogleMarkers() {
    final markers = <gmaps.Marker>{};

    // Store marker (blue pin with store icon) - only if store exists
    if (widget.tracking.store != null) {
      markers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('store'),
        position: gmaps.LatLng(
          widget.tracking.store!.latitude,
          widget.tracking.store!.longitude,
        ),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueBlue,
        ),
        infoWindow: gmaps.InfoWindow(
          title: widget.tracking.store!.name,
          snippet: 'Pickup Location',
        ),
        anchor: const Offset(0.5, 1.0),
      ));
    }

    // Delivery partner marker (animated, orange) - only if assigned
    if (widget.tracking.deliveryPartner != null && 
        widget.tracking.currentLocation != null) {
      final partnerLocation = _animatedPartnerLocation ??
          LatLng(
            widget.tracking.currentLocation!.latitude,
            widget.tracking.currentLocation!.longitude,
          );

      markers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('partner'),
        position: gmaps.LatLng(partnerLocation.latitude, partnerLocation.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueOrange,
        ),
        infoWindow: gmaps.InfoWindow(
          title: widget.tracking.deliveryPartner?.name ?? 'Delivery Partner',
          snippet: 'On the way',
        ),
        rotation: _calculateBearing(
          _previousPartnerLocation ?? partnerLocation,
          partnerLocation,
        ),
        anchor: const Offset(0.5, 0.5),
        flat: true, // Makes rotation smooth
      ));
    }

    // Destination marker (green pin)
    if (widget.tracking.destination.latitude != null &&
        widget.tracking.destination.longitude != null) {
      markers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('destination'),
        position: gmaps.LatLng(
          widget.tracking.destination.latitude!,
          widget.tracking.destination.longitude!,
        ),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueGreen,
        ),
        infoWindow: gmaps.InfoWindow(
          title: 'Delivery Address',
          snippet: widget.tracking.destination.address,
        ),
        anchor: const Offset(0.5, 1.0),
      ));
    }

    setState(() {
      _googleMarkers = markers;
      _updateGooglePolylines();
    });
  }

  void _updateGooglePolylines() {
    final polylines = <gmaps.Polyline>{};

    // Only draw polylines if:
    // 1. Destination has coordinates
    // 2. Delivery partner is assigned
    if (widget.tracking.destination.latitude == null ||
        widget.tracking.destination.longitude == null ||
        widget.tracking.deliveryPartner == null) {
      setState(() {
        _googlePolylines = polylines;
      });
      return;
    }

    // Use fetched route points if available
    if (_routePoints.isNotEmpty) {
      // Main route polyline (following actual roads)
      polylines.add(gmaps.Polyline(
        polylineId: const gmaps.PolylineId('main_route'),
        points: _routePoints,
        color: AppColors.primary,
        width: 5,
        startCap: gmaps.Cap.roundCap,
        endCap: gmaps.Cap.roundCap,
        jointType: gmaps.JointType.round,
      ));

      // Add animated dashed overlay for visual effect
      polylines.add(gmaps.Polyline(
        polylineId: const gmaps.PolylineId('route_overlay'),
        points: _routePoints,
        color: Colors.white,
        width: 2,
        patterns: [
          gmaps.PatternItem.dash(20),
          gmaps.PatternItem.gap(15),
        ],
      ));
    }

    // Add history polyline if available (completed route)
    if (widget.history != null && widget.history!.isNotEmpty) {
      polylines.add(gmaps.Polyline(
        polylineId: const gmaps.PolylineId('history'),
        points: widget.history!
            .map((point) => gmaps.LatLng(point.latitude, point.longitude))
            .toList(),
        color: Colors.green.withValues(alpha: 0.6),
        width: 4,
        startCap: gmaps.Cap.roundCap,
        endCap: gmaps.Cap.roundCap,
      ));
    }

    setState(() {
      _googlePolylines = polylines;
    });
  }

  void _updateOSMMarkers() {
    final markers = <Marker>[];

    // Store marker (blue with shadow) - only if store exists
    if (widget.tracking.store != null) {
      markers.add(Marker(
        point: LatLng(
          widget.tracking.store!.latitude,
          widget.tracking.store!.longitude,
        ),
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shadow
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            // Main marker
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ));
    }

    // Delivery partner marker (animated, orange with shadow) - only if assigned
    if (widget.tracking.deliveryPartner != null && 
        widget.tracking.currentLocation != null) {
      final partnerLocation = _animatedPartnerLocation ??
          LatLng(
            widget.tracking.currentLocation!.latitude,
            widget.tracking.currentLocation!.longitude,
          );

      markers.add(Marker(
        point: partnerLocation,
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing shadow effect
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            // Main marker
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ));
    }

    // User's current location marker (green - from device GPS)
    if (_userCurrentLocation != null) {
      markers.add(Marker(
        point: LatLng(
          _userCurrentLocation!.latitude,
          _userCurrentLocation!.longitude,
        ),
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shadow
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            // Main marker
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(
                Icons.person_pin_circle_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ));
    }

    setState(() {
      _osmMarkers = markers;
      _updateOSMPolylines();
    });
  }

  void _updateOSMPolylines() {
    final polylines = <Polyline>[];

    // Only draw polylines if:
    // 1. Destination has coordinates
    // 2. Delivery partner is assigned
    if (widget.tracking.destination.latitude == null ||
        widget.tracking.destination.longitude == null ||
        widget.tracking.deliveryPartner == null) {
      setState(() {
        _osmPolylines = polylines;
      });
      return;
    }

    // Use fetched route points if available
    if (_osmRoutePoints.isNotEmpty) {
      // Main route polyline (following actual roads)
      polylines.add(Polyline(
        points: _osmRoutePoints,
        color: AppColors.primary,
        strokeWidth: 5,
        borderStrokeWidth: 2,
        borderColor: AppColors.primary.withValues(alpha: 0.3),
      ));
    }

    // Add history polyline if available (completed route)
    if (widget.history != null && widget.history!.isNotEmpty) {
      polylines.add(Polyline(
        points: widget.history!
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(),
        color: Colors.green.withValues(alpha: 0.6),
        strokeWidth: 4,
      ));
    }

    setState(() {
      _osmPolylines = polylines;
    });
  }

  /// Calculate bearing between two points for marker rotation
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// Auto-zoom to fit all markers (Premium-style) - Google Maps
  void _fitGoogleMapBounds() {
    if (_googleMapController == null || _googleMarkers.isEmpty) return;

    // If only one marker (store only), center on it with good zoom
    if (_googleMarkers.length == 1) {
      _googleMapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          _googleMarkers.first.position,
          15,
        ),
      );
      return;
    }

    // Calculate bounds
    final bounds = _calculateGoogleBounds();
    
    // Calculate distance to determine appropriate padding
    final distance = _calculateDistance(
      bounds.southwest.latitude,
      bounds.southwest.longitude,
      bounds.northeast.latitude,
      bounds.northeast.longitude,
    );
    
    // Use less padding for closer markers, more for distant ones
    double padding = 80;
    if (distance < 1) {
      padding = 100; // Very close
    } else if (distance < 3) {
      padding = 80; // Close
    } else if (distance < 10) {
      padding = 60; // Medium
    } else {
      padding = 40; // Far
    }
    
    _googleMapController!.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  gmaps.LatLngBounds _calculateGoogleBounds() {
    double? minLat, maxLat, minLng, maxLng;

    for (final marker in _googleMarkers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : math.min(minLat, lat);
      maxLat = maxLat == null ? lat : math.max(maxLat, lat);
      minLng = minLng == null ? lng : math.min(minLng, lng);
      maxLng = maxLng == null ? lng : math.max(maxLng, lng);
    }

    return gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat!, minLng!),
      northeast: gmaps.LatLng(maxLat!, maxLng!),
    );
  }

  /// Auto-zoom to fit all markers - OSM
  void _fitOSMMapBounds() {
    if (_osmMapController == null || _osmMarkers.isEmpty) {
      return;
    }

    // If only one marker, center on it with good zoom
    if (_osmMarkers.length == 1) {
      final point = _osmMarkers.first.point;
      _osmMapController!.move(point, 15);
      return;
    }

    // Calculate bounds and fit with padding
    final bounds = _calculateOSMBounds();
    
    // Calculate distance between bounds to determine appropriate zoom
    final distance = _calculateDistance(
      bounds.southWest.latitude,
      bounds.southWest.longitude,
      bounds.northEast.latitude,
      bounds.northEast.longitude,
    );
    
    // Determine zoom level based on distance
    double zoom = 15;
    if (distance < 1) {
      zoom = 16; // Very close (< 1km)
    } else if (distance < 3) {
      zoom = 14; // Close (1-3km)
    } else if (distance < 10) {
      zoom = 13; // Medium (3-10km)
    } else {
      zoom = 12; // Far (> 10km)
    }
    
    _osmMapController!.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
        maxZoom: zoom,
        minZoom: 12,
      ),
    );
  }

  LatLngBounds _calculateOSMBounds() {
    double? minLat, maxLat, minLng, maxLng;

    for (final marker in _osmMarkers) {
      final lat = marker.point.latitude;
      final lng = marker.point.longitude;

      minLat = minLat == null ? lat : math.min(minLat, lat);
      maxLat = maxLat == null ? lat : math.max(maxLat, lat);
      minLng = minLng == null ? lng : math.min(minLng, lng);
      maxLng = maxLng == null ? lng : math.max(maxLng, lng);
    }

    return LatLngBounds(
      LatLng(minLat!, minLng!),
      LatLng(maxLat!, maxLng!),
    );
  }

  /// Center map on user's current location (Google Maps style)
  void _centerOnUserLocation(MapProvider mapProvider) {
    if (_userCurrentLocation == null) return;

    final userLat = _userCurrentLocation!.latitude;
    final userLng = _userCurrentLocation!.longitude;

    if (mapProvider == MapProvider.google) {
      // Google Maps
      _googleMapController?.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: gmaps.LatLng(userLat, userLng),
            zoom: 18, // Higher zoom for more detail
          ),
        ),
      );
    } else {
      // OpenStreetMap
      _osmMapController?.move(
        LatLng(userLat, userLng),
        18, // Higher zoom for more detail
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, state) {
        final mapProvider = state is AppConfigLoaded
            ? state.config.mapProvider
            : MapProvider.osm;

        return Stack(
          children: [
            if (mapProvider == MapProvider.google)
              _buildGoogleMap()
            else
              _buildOSMMap(),
            
            // Map controls overlay (Zoom In, Zoom Out, Recenter)
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  // Zoom In
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        if (_googleMapController != null) {
                          _googleMapController!.animateCamera(gmaps.CameraUpdate.zoomIn());
                        } else if (_osmMapController != null) {
                          _osmMapController!.move(
                            _osmMapController!.camera.center,
                            _osmMapController!.camera.zoom + 1,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Zoom Out
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        if (_googleMapController != null) {
                          _googleMapController!.animateCamera(gmaps.CameraUpdate.zoomOut());
                        } else if (_osmMapController != null) {
                          _osmMapController!.move(
                            _osmMapController!.camera.center,
                            _osmMapController!.camera.zoom - 1,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.remove, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Recenter location button
                  if (_userCurrentLocation != null)
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _centerOnUserLocation(mapProvider),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Show warning if destination coordinates are missing or delivery partner not assigned
            if (widget.tracking.destination.latitude == null ||
                widget.tracking.destination.longitude == null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[900], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivery address location not available',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (widget.tracking.deliveryPartner == null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[900], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Waiting for delivery partner assignment',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleMap() {
    // Default center (store location or fallback)
    final storeLat = widget.tracking.store?.latitude ?? 12.9352;
    final storeLng = widget.tracking.store?.longitude ?? 77.6245;
    
    final initialPosition = gmaps.CameraPosition(
      target: gmaps.LatLng(storeLat, storeLng),
      zoom: 14,
    );

    // Professional map style (similar to Blinkit)
    const mapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [{"color": "#ffffff"}]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#9ca5b3"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#c9e6f7"}]
      },
      {
        "featureType": "landscape",
        "elementType": "geometry",
        "stylers": [{"color": "#f5f5f5"}]
      }
    ]
    ''';

    return gmaps.GoogleMap(
      initialCameraPosition: initialPosition,
      style: mapStyle,
      markers: _googleMarkers,
      polylines: _googlePolylines,
      onMapCreated: (controller) {
        _googleMapController = controller;
        _fitGoogleMapBounds();
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      mapType: gmaps.MapType.normal,
      minMaxZoomPreference: const gmaps.MinMaxZoomPreference(12, 20),
      rotateGesturesEnabled: false, // Disable rotation
      tiltGesturesEnabled: false, // Disable tilt/3D view
    );
  }

  Widget _buildOSMMap() {
    // Calculate center point between store and user location
    double centerLat = 12.9352; // Lalli Lane default
    double centerLng = 77.6245;
    double initialZoom = 14;
    
    // If we have both store and user location, center between them
    if (widget.tracking.store != null && _userCurrentLocation != null) {
      centerLat = (widget.tracking.store!.latitude + _userCurrentLocation!.latitude) / 2;
      centerLng = (widget.tracking.store!.longitude + _userCurrentLocation!.longitude) / 2;
      
      // Calculate distance to determine zoom
      final distance = _calculateDistance(
        widget.tracking.store!.latitude,
        widget.tracking.store!.longitude,
        _userCurrentLocation!.latitude,
        _userCurrentLocation!.longitude,
      );
      
      if (distance < 1) {
        initialZoom = 15;
      } else if (distance < 3) {
        initialZoom = 14;
      } else if (distance < 10) {
        initialZoom = 13;
      } else {
        initialZoom = 12;
      }
    }
    // Use user's device location if available
    else if (_userCurrentLocation != null) {
      centerLat = _userCurrentLocation!.latitude;
      centerLng = _userCurrentLocation!.longitude;
      initialZoom = 15;
    } 
    // Fallback to store if available
    else if (widget.tracking.store != null && widget.tracking.store!.latitude != 0) {
      centerLat = widget.tracking.store!.latitude;
      centerLng = widget.tracking.store!.longitude;
      initialZoom = 15;
    }

    return FlutterMap(
      mapController: _osmMapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: initialZoom,
        minZoom: 12,
        maxZoom: 19,
        backgroundColor: const Color(0xFFF5F5F5),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          enableMultiFingerGestureRace: false,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: AppConstants.packageName,
          tileProvider: NetworkTileProvider(),
          maxZoom: 19,
          maxNativeZoom: 19,
          keepBuffer: 2,
          panBuffer: 0,
        ),
        if (_osmPolylines.isNotEmpty)
          PolylineLayer(polylines: _osmPolylines),
        if (_osmMarkers.isNotEmpty)
          MarkerLayer(markers: _osmMarkers),
      ],
    );
  }
}
