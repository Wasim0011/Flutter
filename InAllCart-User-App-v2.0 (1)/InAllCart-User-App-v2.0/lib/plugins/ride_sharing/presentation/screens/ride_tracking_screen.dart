import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ride_models.dart';
import '../../data/repositories/ride_sharing_repository.dart';
import '../../../../core/di/injection.dart';

class RideTrackingScreen extends StatefulWidget {
  final RideBookingModel booking;

  const RideTrackingScreen({super.key, required this.booking});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  late RideBookingModel _currentBooking;
  Timer? _trackingTimer;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _startPeriodicTracking();
  }

  bool _hasShownRating = false;

  void _startPeriodicTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      // P-1 FIX: Don't poll for completed/cancelled rides
      final status = _currentBooking.status.toLowerCase();
      if (status == 'completed' || status == 'cancelled') {
        _trackingTimer?.cancel();
        return;
      }

      try {
        final repository = getIt<RideSharingRepository>();
        final updated = await repository.trackRide(_currentBooking.id);
        if (mounted) {
          setState(() {
            _currentBooking = updated;
          });
          _animateCameraToDriver(updated);
          _checkCompletionStatus(updated);
        }
      } catch (_) {
        // Periodic check fail fallback — non-fatal
      }
    });
  }

  /// M-6 FIX: Animate map camera to follow driver location updates
  void _animateCameraToDriver(RideBookingModel booking) {
    if (_mapController == null) return;
    if (booking.driverLat != null && booking.driverLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(booking.driverLat!, booking.driverLng!)),
      );
    }
  }

  void _checkCompletionStatus(RideBookingModel booking) {
    if (booking.status.toLowerCase() == 'completed' && !_hasShownRating) {
      _hasShownRating = true;
      _trackingTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRatingDialog();
      });
    }
  }

  void _showRatingDialog() {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                children: const [
                  Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
                  SizedBox(height: 8),
                  Text('Rate Your Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How was your ride with ${_currentBooking.driverName ?? "the driver"}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1.0;
                      return IconButton(
                        icon: Icon(
                          starVal <= selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment (optional)...',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    commentController.dispose();
                    Navigator.pop(ctx);
                    context.go('/ride-sharing');
                  },
                  child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final repo = getIt<RideSharingRepository>();
                    final success = await repo.rateRide(
                      _currentBooking.id,
                      selectedRating,
                      comment: commentController.text,
                    );
                    commentController.dispose();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to submit rating. Please try again.')),
                        );
                      }
                      if (context.mounted) context.go('/ride-sharing');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Rating', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// U-3 FIX: Confirmation dialog before cancelling
  void _confirmCancelRide() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to cancel this ride? A cancellation fee may apply if the driver has already accepted.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('No, Keep Ride', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final repo = getIt<RideSharingRepository>();
              final success = await repo.cancelRide(_currentBooking.id);
              if (!mounted) return;
              if (success) {
                context.go('/ride-sharing');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to cancel ride. It may already be in progress.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  /// Helper: determine if ride can be cancelled at current status
  bool get _canCancelRide {
    final status = _currentBooking.status.toLowerCase();
    return status == 'pending' ||
        status == 'searching' ||
        status == 'accepted' ||
        status == 'arriving' ||
        status == 'arrived';
  }

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(_currentBooking.pickupLat, _currentBooking.pickupLng);
    final dropoff = LatLng(_currentBooking.dropoffLat, _currentBooking.dropoffLng);
    final driverLoc = (_currentBooking.driverLat != null && _currentBooking.driverLng != null)
        ? LatLng(_currentBooking.driverLat!, _currentBooking.driverLng!)
        : pickup;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map Track
          GoogleMap(
            initialCameraPosition: CameraPosition(target: pickup, zoom: 14.5),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickup,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: dropoff,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
              if (_currentBooking.driverName != null)
                Marker(
                  markerId: const MarkerId('driver'),
                  position: driverLoc,
                  infoWindow: InfoWindow(title: _currentBooking.driverName),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('track_route'),
                color: AppColors.primary,
                width: 5,
                points: [pickup, driverLoc, dropoff],
              ),
            },
            zoomControlsEnabled: false,
          ),

          // Top Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/ride-sharing');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _currentBooking.rideNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(_currentBooking.status),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Info Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // U-1 FIX: OTP Banner with Flexible wrapping to prevent overflow
                  if (_currentBooking.otp != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Share OTP with driver:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currentBooking.otp!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Driver Details Card
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 30, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentBooking.driverName ?? 'Searching for nearby driver...',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${_currentBooking.vehicleName ?? "Taxi"} • ${_currentBooking.vehicleNumber ?? "DL 01 AB 1234"}',
                              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (_currentBooking.driverPhone != null)
                        CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: const Icon(Icons.phone, color: Colors.green),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fare & Addresses
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Fare: ₹${_currentBooking.totalFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Payment: ${_currentBooking.paymentMethod.toUpperCase()}',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (SOS & Cancel)
                  Row(
                    children: [
                      // SOS button — always visible during active rides
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // M-1 FIX: Pass actual coordinates to SOS trigger
                            final repo = getIt<RideSharingRepository>();
                            final success = await repo.triggerSOS(
                              _currentBooking.id,
                              lat: _currentBooking.pickupLat,
                              lng: _currentBooking.pickupLng,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? '🚨 SOS Alert sent to emergency contacts!'
                                      : '⚠️ SOS failed. Please call emergency services directly.'),
                                  backgroundColor: success ? null : Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.warning, color: Colors.red),
                          label: const Text('SOS Emergency',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      // U-2 FIX: Only show cancel button for cancellable statuses
                      if (_canCancelRide) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            // U-3 FIX: Show confirmation dialog instead of immediate cancel
                            onPressed: _confirmCancelRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text('Cancel Ride',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'accepted':
      case 'arriving':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        label = 'Driver En Route';
        break;
      case 'arrived':
        bg = Colors.purple.shade50;
        text = Colors.purple.shade700;
        label = 'Driver Arrived';
        break;
      case 'in_transit':
      case 'started':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        label = 'In Transit';
        break;
      case 'completed':
        bg = Colors.green.shade100;
        text = Colors.green.shade900;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        label = 'Cancelled';
        break;
      default:
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        label = 'Finding Driver';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
