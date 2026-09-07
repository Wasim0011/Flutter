import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationResult {
  final Position? position;
  final LocationStatus status;

  LocationResult({this.position, required this.status});
}

class LocationService {
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> checkPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<LocationStatus> getLocationStatus() async {
    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationStatus.serviceDisabled;
    }

    // Check permission status
    final status = await Permission.location.status;
    if (status.isGranted) {
      return LocationStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return LocationStatus.deniedForever;
    } else {
      return LocationStatus.denied;
    }
  }

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  Future<Position?> getCurrentLocation({Duration? timeout}) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final effectiveTimeout = timeout ?? const Duration(seconds: 10);

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(effectiveTimeout);
    } catch (_) {
      // High accuracy timed out — fall back to low accuracy
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            distanceFilter: 0,
          ),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Try last known position as final fallback
        return await Geolocator.getLastKnownPosition();
      }
    }
  }

  Future<LocationResult> getCurrentLocationWithStatus() async {
    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(status: LocationStatus.serviceDisabled);
    }

    // Check and request permission
    var permission = await Permission.location.status;
    if (!permission.isGranted) {
      permission = await Permission.location.request();
    }

    if (permission.isPermanentlyDenied) {
      return LocationResult(status: LocationStatus.deniedForever);
    }

    if (!permission.isGranted) {
      return LocationResult(status: LocationStatus.denied);
    }

    // Get position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      return LocationResult(position: position, status: LocationStatus.granted);
    } catch (e) {
      return LocationResult(status: LocationStatus.serviceDisabled);
    }
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<double> calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
