import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/di/injection.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../../../features/app_config/domain/entities/app_config.dart';
import '../bloc/ride_sharing_bloc.dart';
import '../bloc/ride_sharing_event.dart';
import '../bloc/ride_sharing_state.dart';
import '../../domain/entities/ride_sharing_entities.dart';
import 'ride_location_search_page.dart';
import 'ride_rating_page.dart';
import '../widgets/ride_initial_sheet.dart';
import '../widgets/ride_vehicle_selection_sheet.dart';
import '../widgets/ride_finding_driver_sheet.dart';
import '../widgets/ride_driver_assigned_sheet.dart';
import '../widgets/ride_dialogs.dart';
import '../widgets/ride_app_drawer.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/widgets/unauthenticated_widget.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../data/services/place_search_service.dart';

enum RideState { initial, selectingVehicle, findingDriver, driverAssigned }

/// Lets the parent shell delegate hardware-back handling to the active ride
/// view. [handleBack] returns true when the ride flow consumed the back press
/// (stepped back a state); false means the shell should handle exit.
class RideHomeBackController {
  bool Function()? _handler;
  void _attach(bool Function() h) => _handler = h;
  void _detach(bool Function() h) {
    if (identical(_handler, h)) _handler = null;
  }

  bool handleBack() => _handler?.call() ?? false;
}

class RideHomePage extends StatelessWidget {
  final RideHomeBackController? backController;
  const RideHomePage({super.key, this.backController});

  @override
  Widget build(BuildContext context) {
    final appConfigState = context.read<AppConfigBloc>().state;
    if (appConfigState is! AppConfigLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final appConfig = appConfigState.config;
    final googleKey = (appConfig.googleMapsApiKey != null && appConfig.googleMapsApiKey!.isNotEmpty)
        ? appConfig.googleMapsApiKey
        : 'AIzaSyBm324WP5IrhHPc34QeYunXCzxryVwr9tU';

    return BlocProvider(
      create: (context) => getIt<RideSharingBloc>()..add(GetVehicleTypesEvent()),
      child: _RideHomeView(backController: backController),
    );
  }
}

class _RideHomeView extends StatefulWidget {
  final RideHomeBackController? backController;
  const _RideHomeView({this.backController});

  @override
  State<_RideHomeView> createState() => _RideHomeViewState();
}

class _RideHomeViewState extends State<_RideHomeView> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _controller;
  RideState _currentState = RideState.initial;

  LatLng _currentLocation = const LatLng(28.6139, 77.2090);
  LatLng? _destination;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  int _selectedVehicleIndex = 0;
  List<VehicleType> _vehicleTypes = [];
  List<FareEstimate> _fareEstimates = [];
  Ride? _currentRide;

  String? _pickupAddress;
  String? _destinationAddress;

  // Stored route coords — used to fire per-vehicle estimates once types load
  double? _pendingPickupLat;
  double? _pendingPickupLng;
  double? _pendingDropoffLat;
  double? _pendingDropoffLng;

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _pollingTimer;
  String _paymentMethod = 'cash';
  List<PaymentMethodInfo> _availablePaymentMethods = [];
  bool _isProcessingPayment = false;
  bool _isPriceBoostRebooking = false;
  String? _promoCode;

  @override
  void initState() {
    super.initState();
    widget.backController?._attach(_consumeBack);
    _getCurrentLocation();
    _setInitialMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideSharingBloc>().add(LoadRidePaymentMethodsEvent());
    });
  }

  /// Called by the shell on hardware-back. Returns true if the ride flow
  /// handled it (stepped back a state); false to let the shell decide.
  bool _consumeBack() {
    switch (_currentState) {
      case RideState.selectingVehicle:
        _resetMap();
        return true;
      case RideState.findingDriver:
        if (_currentRide != null) {
          context.read<RideSharingBloc>().add(
              CancelRideEvent(rideId: _currentRide!.id, reason: 'Changed mind'));
        } else {
          _resetMap();
        }
        return true;
      case RideState.driverAssigned:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You have an active ride. Use SOS or contact your captain.'),
          ),
        );
        return true;
      case RideState.initial:
        return false;
    }
  }

  @override
  void dispose() {
    widget.backController?._detach(_consumeBack);
    _positionStreamSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  CurrencyConfig _getCurrencyConfig() {
    final appConfigState = context.read<AppConfigBloc>().state;
    if (appConfigState is AppConfigLoaded) {
      return appConfigState.config.currencyConfig;
    }
    return const CurrencyConfig(
      defaultCurrency: 'INR',
      symbol: '?',
      symbolPosition: 'left',
      decimalPlaces: 0,
      thousandSeparator: ',',
      multiCurrencyEnabled: false,
      supportedCurrencies: {},
    );
  }

  void _startPolling(RideState state) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _currentRide == null) {
        timer.cancel();
        return;
      }
      if (state == RideState.findingDriver) {
        context.read<RideSharingBloc>().add(CheckRideStatusEvent(rideId: _currentRide!.id));
      } else if (state == RideState.driverAssigned) {
        context.read<RideSharingBloc>().add(TrackRideEvent(rideId: _currentRide!.id));
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _updateDriverMarker(RideDriver? driver) {
    if (driver == null || driver.latitude == null || driver.longitude == null) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId == const MarkerId('driver'));
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(driver.latitude!, driver.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Captain Location'),
      ));
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final loc = LatLng(position.latitude, position.longitude);
      final placeService = PlaceSearchService();
      final address = await placeService.reverseGeocode(loc);
      if (mounted) {
        setState(() {
          _currentLocation = loc;
          _pickupAddress = address;
        });
        _setInitialMarkers();
        _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 15.0));
      }
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position position) async {
        final newLoc = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            _currentLocation = newLoc;
          });
          _setInitialMarkers();
        }
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _setInitialMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        )
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
    _controller = controller;
    controller.setMapStyle('''[{"featureType":"all","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},{"featureType":"all","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"all","elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"},{"weight":2}]},{"featureType":"administrative","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#eeeeee"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#424242"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#e0e0e0"},{"weight":1}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#e5e5e5"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9c9c9"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]}]''');
  }

  void _setupRoute() {
    if (_destination == null) return;
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: _destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop-off Location'),
      ));
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: [_currentLocation, _destination!],
          color: Colors.black.withOpacity(0.5),
          width: 2,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        )
      };
      _currentState = RideState.selectingVehicle;
    });

    // Store route coords for estimate calls
    _pendingPickupLat = _currentLocation.latitude;
    _pendingPickupLng = _currentLocation.longitude;
    _pendingDropoffLat = _destination!.latitude;
    _pendingDropoffLng = _destination!.longitude;

    _animateToFitBounds();

    // Dispatch estimate for each already-loaded vehicle type
    _dispatchEstimatesForAllVehicles();
  }

  /// Fires one GetFareEstimateEvent per vehicle type (backend requires vehicle_type_id).
  void _dispatchEstimatesForAllVehicles() {
    if (_pendingPickupLat == null || _pendingDropoffLat == null) return;
    if (_vehicleTypes.isEmpty) return; // Will be triggered again from VehicleTypesLoaded listener
    for (final vehicle in _vehicleTypes) {
      context.read<RideSharingBloc>().add(GetFareEstimateEvent(
        pickupLat: _pendingPickupLat!,
        pickupLng: _pendingPickupLng!,
        dropoffLat: _pendingDropoffLat!,
        dropoffLng: _pendingDropoffLng!,
        vehicleTypeId: vehicle.id,
      ));
    }
  }

  void _animateToFitBounds() {
    if (_controller == null || _destination == null) return;
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        math.min(_currentLocation.latitude, _destination!.latitude),
        math.min(_currentLocation.longitude, _destination!.longitude),
      ),
      northeast: LatLng(
        math.max(_currentLocation.latitude, _destination!.latitude),
        math.max(_currentLocation.longitude, _destination!.longitude),
      ),
    );
    _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
  }

  void _resetMap() {
    _stopPolling();
    setState(() {
      _destination = null;
      _destinationAddress = null;
      _polylines.clear();
      _setInitialMarkers();
      _currentState = RideState.initial;
      _currentRide = null;
      _pendingPickupLat = null;
      _pendingPickupLng = null;
      _pendingDropoffLat = null;
      _pendingDropoffLng = null;
    });
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 16.0));
  }

  void _updateRouteWithPolyline(String polylineStr) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(polylineStr);
    if (result.isEmpty) return;
    List<LatLng> points = result.map((p) => LatLng(p.latitude, p.longitude)).toList();
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: points,
          color: Colors.black,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        )
      };
    });
    _animateToFitBoundsWithPoints(points);
  }

  void _animateToFitBoundsWithPoints(List<LatLng> points) {
    if (_controller == null || points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _controller!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      80.0,
    ));
  }

  double _getMapBottomPadding() {
    switch (_currentState) {
      case RideState.initial:
        return 260.0;
      case RideState.selectingVehicle:
        return 500.0;
      case RideState.findingDriver:
        return 220.0;
      case RideState.driverAssigned:
        return 320.0;
    }
  }

  Future<void> _openLocationSearch({String activeField = 'dropoff'}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => RideLocationSearchPage(
          activeField: activeField,
          currentLocation: _currentLocation,
          initialPickupAddress: _pickupAddress,
          initialDropoffAddress: _destinationAddress,
        ),
      ),
    );
    if (result != null) {
      final pickupLoc = result['pickup_location'] as LatLng?;
      final dropoffLoc = result['dropoff_location'] as LatLng?;
      final pickupName = result['pickup_name'] as String?;
      final dropoffName = result['dropoff_name'] as String?;
      if (dropoffLoc != null) {
        setState(() {
          if (pickupLoc != null) _currentLocation = pickupLoc;
          _destination = dropoffLoc;
          _pickupAddress = pickupName ?? 'Current Location';
          _destinationAddress = dropoffName ?? 'Destination';
        });
        _setupRoute();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RideSharingBloc, RideSharingState>(
      listener: (context, state) {
        if (state is VehicleTypesLoaded) {
          setState(() => _vehicleTypes = state.vehicleTypes);
          // If a route is already set, fire estimates now that we have vehicle types
          _dispatchEstimatesForAllVehicles();
        } else if (state is FareEstimateLoaded) {
          setState(() {
            _fareEstimates = state.fareEstimates;
            if (_fareEstimates.isNotEmpty && _fareEstimates.first.polyline != null) {
              _updateRouteWithPolyline(_fareEstimates.first.polyline!);
            }
          });
        } else if (state is RideSearching) {
          setState(() {
            _currentRide = state.ride;
            _currentState = RideState.findingDriver;
          });
          _startPolling(RideState.findingDriver);
          _controller?.animateCamera(CameraUpdate.zoomTo(14.0));
        } else if (state is DriverAssigned) {
          setState(() {
            _currentRide = state.ride;
            _currentState = RideState.driverAssigned;
          });
          _startPolling(RideState.driverAssigned);
          _updateDriverMarker(state.ride.driver);
          _controller?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentLocation, zoom: 16.0, tilt: 0)));
        } else if (state is RideCompleted) {
          _stopPolling();
          _showRideCompletedDialog(state.ride);
        } else if (state is RideTrackingUpdate) {
          setState(() {
            _currentRide = state.ride;
            if (_currentState == RideState.findingDriver && state.ride.driverId != null) {
              _currentState = RideState.driverAssigned;
            }
          });
          _updateDriverMarker(state.ride.driver);
        } else if (state is RidePaymentRequired) {
          context.read<RideSharingBloc>().add(InitializeRidePaymentEvent(
            rideId: state.ride.id,
            paymentMethod: state.paymentMethod,
            amount: state.ride.totalFare,
            context: context,
          ));
        } else if (state is RideCancelled) {
          _stopPolling();
          // If this cancel was triggered by a price boost re-booking,
          // don't reset the map or show the snackbar — the re-book will fire.
          if (_isPriceBoostRebooking) {
            _isPriceBoostRebooking = false;
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Ride cancelled')));
            _resetMap();
          }
        } else if (state is RidePaymentMethodsLoaded) {
          setState(() => _availablePaymentMethods = state.methods);
        } else if (state is RidePaymentProcessing) {
          setState(() => _isProcessingPayment = true);
        } else if (state is RidePaymentSuccess) {
          setState(() => _isProcessingPayment = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Payment successful! Finding driver...'),
              backgroundColor: Colors.green));
          if (_currentRide != null) {
            setState(() => _currentState = RideState.findingDriver);
            _startPolling(RideState.findingDriver);
          }
        } else if (state is RidePaymentError) {
          setState(() => _isProcessingPayment = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        } else if (state is RideSharingError) {
          setState(() => _isProcessingPayment = false);
          // During findingDriver state, ignore transient auth errors from
          // polling — the token may just need refreshing and the next poll
          // will succeed. Only show auth sheet when NOT actively searching.
          final isAuthError =
              state.message.toLowerCase().contains('unauthenticated') ||
              state.message.contains('401') ||
              state.message.toLowerCase().contains('logged in');

          if (_currentState == RideState.findingDriver) {
            // Silently ignore auth errors during driver search to prevent
            // the "Unauthorized" flash. Non-auth errors just show a snackbar
            // but do NOT kick back to vehicle selection.
            if (!isAuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          } else {
            if (isAuthError) {
              UnauthenticatedWidget.showSheet(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          }
        } else if (state is SOSError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('SOS failed: ${state.message}'),
              backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        return Scaffold(
            key: _scaffoldKey,
            drawer: RideAppDrawer(),
            body: Stack(
            children: [
              // -- Full-screen map --------------------------------------
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _currentLocation, zoom: 15.0, tilt: 0, bearing: 0),
                onMapCreated: _onMapCreated,
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                buildingsEnabled: false,
                trafficEnabled: false,
                indoorViewEnabled: false,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: false,
                padding: EdgeInsets.only(bottom: _getMapBottomPadding()),
                minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
              ),

              // -- Top-left: Menu (initial) / Back (other states) ------
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: Row(
                  children: [
                    _buildFloatingCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        if (_currentState == RideState.initial) {
                          context.go('/home');
                        } else if (_currentState == RideState.findingDriver &&
                            _currentRide != null) {
                          context.read<RideSharingBloc>().add(CancelRideEvent(
                              rideId: _currentRide!.id, reason: 'Changed mind'));
                        } else {
                          _resetMap();
                        }
                      },
                    ),
                    if (_currentState == RideState.initial) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const AppLogo(height: 40, transparentBackground: true),
                      ),
                    ],
                  ],
                ),
              ),

              // -- Top-right: Close + My Location (initial only) --------
              if (_currentState == RideState.initial)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: Row(
                    children: [
                      _buildFloatingCircleButton(
                        icon: Icons.my_location,
                        onTap: () async {
                          try {
                            final position = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high);
                            final loc = LatLng(position.latitude, position.longitude);
                            setState(() => _currentLocation = loc);
                            _setInitialMarkers();
                            _controller?.animateCamera(CameraUpdate.newCameraPosition(
                                CameraPosition(target: loc, zoom: 15.0, tilt: 0, bearing: 0)));
                          } catch (_) {
                            _controller?.animateCamera(CameraUpdate.newCameraPosition(
                                CameraPosition(
                                    target: _currentLocation, zoom: 15.0, tilt: 0, bearing: 0)));
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildFloatingCircleButton(
                        icon: Icons.close_rounded,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                    ],
                  ),
                ),

              // -- Bottom sheet -----------------------------------------
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomSheet(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingCircleButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  Widget _buildBottomSheet(RideSharingState state) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1F000000), blurRadius: 28, offset: Offset(0, -6))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _getStateWidget(state),
          ),
        ],
      ),
    );
  }

  Widget _getStateWidget(RideSharingState state) {
    switch (_currentState) {
      case RideState.initial:
        return RideInitialSheet(
          key: const ValueKey('initial'),
          pickupAddress: _pickupAddress,
          destinationAddress: _destinationAddress,
          vehicleTypes: _vehicleTypes,
          onSearchTap: () => _openLocationSearch(activeField: 'dropoff'),
        );

      case RideState.selectingVehicle:
        return RideVehicleSelectionSheet(
          key: const ValueKey('selecting'),
          pickupAddress: _pickupAddress,
          destinationAddress: _destinationAddress,
          vehicleTypes: _vehicleTypes,
          fareEstimates: _fareEstimates,
          selectedIndex: _selectedVehicleIndex,
          paymentMethod: _paymentMethod,
          availablePaymentMethods: _availablePaymentMethods,
          promoCode: _promoCode,
          isLoading: state is RideSharingLoading || _isProcessingPayment,
          currency: _getCurrencyConfig(),
          onVehicleSelected: (i) => setState(() => _selectedVehicleIndex = i),
          onEditRoute: () => _openLocationSearch(activeField: 'dropoff'),
          onPaymentTap: () => showPaymentMethodPicker(
            context: context,
            currentMethod: _paymentMethod,
            availableMethods: _availablePaymentMethods,
            onSelected: (m) => setState(() => _paymentMethod = m),
          ),
          onPromoTap: () => showPromoCodeDialog(
            context: context,
            currentCode: _promoCode,
            onApply: (code) => setState(() => _promoCode = code),
          ),
          onPromoRemove: () => setState(() => _promoCode = null),
          onBook: () {
            if (_destination == null || _vehicleTypes.isEmpty) return;

            final authState = context.read<AuthBloc>().state;
            if (authState is Unauthenticated) {
              UnauthenticatedWidget.showSheet(context, onLoginSuccess: () {
                final vehicle = _vehicleTypes[
                    _selectedVehicleIndex.clamp(0, _vehicleTypes.length - 1)];
                context.read<RideSharingBloc>().add(BookRideEvent(
                  pickupLat: _currentLocation.latitude,
                  pickupLng: _currentLocation.longitude,
                  pickupAddress: _pickupAddress ?? 'Current Location',
                  dropoffLat: _destination!.latitude,
                  dropoffLng: _destination!.longitude,
                  dropoffAddress: _destinationAddress ?? 'Destination',
                  vehicleTypeId: vehicle.id,
                  paymentMethod: _paymentMethod,
                  promoCode: _promoCode,
                ));
              });
              return;
            }

            final vehicle = _vehicleTypes[
                _selectedVehicleIndex.clamp(0, _vehicleTypes.length - 1)];
            context.read<RideSharingBloc>().add(BookRideEvent(
              pickupLat: _currentLocation.latitude,
              pickupLng: _currentLocation.longitude,
              pickupAddress: _pickupAddress ?? 'Current Location',
              dropoffLat: _destination!.latitude,
              dropoffLng: _destination!.longitude,
              dropoffAddress: _destinationAddress ?? 'Destination',
              vehicleTypeId: vehicle.id,
              paymentMethod: _paymentMethod,
              promoCode: _promoCode,
            ));
          },
        );

      case RideState.findingDriver:
        // Extract current fare from active ride or selected vehicle's estimate
        double currentFare = _currentRide?.totalFare ?? 0;
        if (currentFare == 0 && _fareEstimates.isNotEmpty && _vehicleTypes.isNotEmpty) {
          final selectedVehicle = _vehicleTypes[
              _selectedVehicleIndex.clamp(0, _vehicleTypes.length - 1)];
          final estimate = _fareEstimates.cast<FareEstimate?>().firstWhere(
                (e) => e?.vehicleType == selectedVehicle.name,
                orElse: () => null,
              );
          currentFare = estimate?.totalFare ?? estimate?.baseFare ?? 0;
        }
        final currency = _getCurrencyConfig();

        return RideFindingDriverSheet(
          key: const ValueKey('finding'),
          rideId: _currentRide?.id,
          isCancelling: state is RideSharingLoading,
          currentFare: currentFare,
          currencySymbol: currency.symbol,
          onCancel: () {
            if (_currentRide != null) {
              context.read<RideSharingBloc>().add(
                  CancelRideEvent(rideId: _currentRide!.id, reason: 'Too long'));
            } else {
              _resetMap();
            }
          },
          onPriceBoost: (boostAmount) {
            // Increase fare on the same booking without cancelling or creating a new order
            if (_currentRide != null) {
              context.read<RideSharingBloc>().add(BoostRideFareEvent(
                rideId: _currentRide!.id,
                boostAmount: boostAmount,
              ));
            }
          },
          onTimeout: () {
            // 5-minute timer expired
            if (_currentRide != null) {
              context.read<RideSharingBloc>().add(
                  CancelRideEvent(rideId: _currentRide!.id, reason: 'Timeout'));
            }
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No drivers found. Please try again or increase your offer.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ));
            _resetMap();
          },
        );

      case RideState.driverAssigned:
        if (_currentRide == null || _currentRide!.driver == null) {
          return const SizedBox.shrink();
        }
        return RideDriverAssignedSheet(
          key: const ValueKey('assigned'),
          ride: _currentRide!,
          currency: _getCurrencyConfig(),
          onCallDriver: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Calling ${_currentRide!.driver!.name}: ${_currentRide!.driver!.phone ?? "N/A"}')),
          ),
          onSOS: () => showSOSConfirmationDialog(
            context: context,
            onConfirm: () {
              if (_currentRide != null) {
                context.read<RideSharingBloc>().add(TriggerSOSEvent(
                  rideId: _currentRide!.id,
                  lat: _currentLocation.latitude,
                  lng: _currentLocation.longitude,
                  message: 'Emergency SOS triggered by rider',
                ));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('SOS Triggered! Admin has been notified.'),
                  backgroundColor: Colors.red,
                ));
              }
            },
          ),
          onShareTrip: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Share trip feature coming soon')),
          ),
        );
    }
  }

  void _showRideCompletedDialog(Ride ride) {
    showRideCompletedDialog(
      context: context,
      ride: ride,
      currency: _getCurrencyConfig(),
      onRate: () {
        _resetMap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AppConfigBloc>(),
              child: RideRatingPage(ride: ride),
            ),
          ),
        );
      },
      onSkip: _resetMap,
    );
  }
}
