import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/ride_sharing_cubit.dart';
import '../../data/models/ride_models.dart';
import '../../data/services/place_search_service.dart';

class RideSharingHomeScreen extends StatefulWidget {
  const RideSharingHomeScreen({super.key});

  @override
  State<RideSharingHomeScreen> createState() => _RideSharingHomeScreenState();
}

class _RideSharingHomeScreenState extends State<RideSharingHomeScreen> {
  GoogleMapController? _mapController;

  LatLng _pickupLocation = const LatLng(0, 0);
  LatLng _dropoffLocation = const LatLng(0, 0);

  String _pickupAddress = 'Fetching current location...';
  String _dropoffAddress = 'Select destination';
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    final cubit = context.read<RideSharingCubit>();
    cubit.loadVehicleTypes();
  }

  Future<void> _fetchCurrentLocation() async {
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
        final placeService = PlaceSearchService();
        final address = await placeService.reverseGeocode(loc);
        if (mounted) {
          setState(() {
            _pickupLocation = loc;
            _pickupAddress = address;
          });
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15.5));
          _onLocationsChanged();
        }
      }
    } catch (_) {
      if (mounted && _pickupAddress.contains('Fetching')) {
        setState(() {
          _pickupAddress = 'Select Pickup Location';
        });
      }
    }
  }

  void _fitMapBounds() {
    if (_mapController != null) {
      final southWest = LatLng(
        _pickupLocation.latitude < _dropoffLocation.latitude ? _pickupLocation.latitude : _dropoffLocation.latitude,
        _pickupLocation.longitude < _dropoffLocation.longitude ? _pickupLocation.longitude : _dropoffLocation.longitude,
      );
      final northEast = LatLng(
        _pickupLocation.latitude > _dropoffLocation.latitude ? _pickupLocation.latitude : _dropoffLocation.latitude,
        _pickupLocation.longitude > _dropoffLocation.longitude ? _pickupLocation.longitude : _dropoffLocation.longitude,
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: southWest, northeast: northEast),
          70,
        ),
      );
    }
  }

  void _onLocationsChanged() {
    _fitMapBounds();
    context.read<RideSharingCubit>().fetchEstimates(
      pickupLat: _pickupLocation.latitude,
      pickupLng: _pickupLocation.longitude,
      pickupAddress: _pickupAddress,
      dropoffLat: _dropoffLocation.latitude,
      dropoffLng: _dropoffLocation.longitude,
      dropoffAddress: _dropoffAddress,
    );
  }

  void _showAddressSearchBottomSheet(bool isPickup) {
    final places = [
      {'title': 'Connaught Place, New Delhi', 'lat': 28.6139, 'lng': 77.2090},
      {'title': 'IGI Airport Terminal 3, Delhi', 'lat': 28.5562, 'lng': 77.1000},
      {'title': 'Cyber City, Gurgaon', 'lat': 28.4950, 'lng': 77.0890},
      {'title': 'Sector 62, Noida', 'lat': 28.5355, 'lng': 77.3910},
      {'title': 'New Delhi Railway Station', 'lat': 28.6430, 'lng': 77.2194},
      {'title': 'Vasant Kunj Promenade, Delhi', 'lat': 28.5380, 'lng': 77.1550},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPickup ? 'Select Pickup Location' : 'Select Destination',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 14),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search landmark or address...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      if (isPickup) {
                        _pickupAddress = val.trim();
                      } else {
                        _dropoffAddress = val.trim();
                      }
                    });
                    Navigator.pop(ctx);
                    _onLocationsChanged();
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Suggested Places', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7280), fontSize: 12)),
              const SizedBox(height: 8),
              ...places.map((place) {
                final title = place['title'] as String;
                final lat = place['lat'] as double;
                final lng = place['lng'] as double;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isPickup ? Icons.circle : Icons.square,
                    color: isPickup ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      if (isPickup) {
                        _pickupAddress = title;
                        _pickupLocation = LatLng(lat, lng);
                      } else {
                        _dropoffAddress = title;
                        _dropoffLocation = LatLng(lat, lng);
                      }
                    });
                    Navigator.pop(ctx);
                    _onLocationsChanged();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map Background View
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickupLocation,
              zoom: 13.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: _pickupLocation,
                infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupAddress),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
              Marker(
                markerId: const MarkerId('dropoff'),
                position: _dropoffLocation,
                infoWindow: InfoWindow(title: 'Destination', snippet: _dropoffAddress),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                color: AppColors.primary,
                width: 5,
                points: [_pickupLocation, _dropoffLocation],
              ),
            },
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Header Controls
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
                        context.go('/home');
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.local_taxi, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text(
                          'Ride Sharing (Taxi)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.history, color: Colors.black),
                    onPressed: () => context.push('/ride-sharing/history'),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Sheet with Vehicle Selection and Booking
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: BlocConsumer<RideSharingCubit, RideSharingState>(
                listener: (context, state) {
                  if (state is RideBookedSuccess) {
                    context.push('/ride-sharing/track', extra: state.booking);
                  } else if (state is RideSharingError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is RideSharingLoading) {
                    return const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is RideTypesLoaded) {
                    final selected = state.selectedType;
                    final estimate = state.estimates.firstWhere(
                      (e) => e.vehicleTypeId == selected?.id,
                      orElse: () => RideEstimateModel(
                        vehicleTypeId: selected?.id ?? 1,
                        vehicleName: selected?.name ?? 'Taxi',
                        distanceKm: 5.2,
                        durationMinutes: 14,
                        estimatedFare: ((selected?.baseFare ?? 30) + 75.0),
                      ),
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Picker Summary Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => _showAddressSearchBottomSheet(true),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, color: Colors.green, size: 14),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _pickupAddress,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.edit, size: 14, color: Colors.grey),
                                  ],
                                ),
                              ),
                              const Divider(height: 16),
                              InkWell(
                                onTap: () => _showAddressSearchBottomSheet(false),
                                child: Row(
                                  children: [
                                    const Icon(Icons.square, color: Colors.red, size: 14),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _dropoffAddress,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.edit, size: 14, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Choose a Ride',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),

                        // Vehicle Selection List
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.vehicleTypes.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final type = state.vehicleTypes[index];
                              final isSelected = type.id == selected?.id;
                              final typeEstimate = state.estimates.firstWhere(
                                (e) => e.vehicleTypeId == type.id,
                                orElse: () => RideEstimateModel(
                                  vehicleTypeId: type.id,
                                  vehicleName: type.name,
                                  distanceKm: 5.2,
                                  durationMinutes: 14,
                                  estimatedFare: (type.baseFare + 75.0),
                                ),
                              );

                              return GestureDetector(
                                onTap: () =>
                                    context.read<RideSharingCubit>().selectVehicleType(type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 110,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (type.iconUrl != null && type.iconUrl!.isNotEmpty)
                                        CachedNetworkImage(
                                          imageUrl: type.iconUrl!,
                                          height: 30,
                                          width: 30,
                                          fit: BoxFit.contain,
                                          errorWidget: (_, __, ___) => Icon(
                                            _getVehicleIcon(type.category),
                                            size: 28,
                                            color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
                                          ),
                                        )
                                      else
                                        Icon(
                                          _getVehicleIcon(type.category),
                                          size: 28,
                                          color: isSelected
                                              ? AppColors.primary
                                              : const Color(0xFF4B5563),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        type.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${typeEstimate.estimatedFare.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Payment & Confirmation Row
                        Row(
                          children: [
                            DropdownButton<String>(
                              value: _paymentMethod,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'cash', child: Text('💵 Cash')),
                                DropdownMenuItem(value: 'wallet', child: Text('👛 Wallet')),
                                DropdownMenuItem(value: 'online', child: Text('💳 Card / UPI')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _paymentMethod = val);
                              },
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Est. Fare: ₹${estimate.estimatedFare.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${estimate.distanceKm} km • ${estimate.durationMinutes.toInt()} min',
                                  style: const TextStyle(
                                      color: Color(0xFF6B7280), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Confirm Booking Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: selected == null
                                ? null
                                : () {
                                    context.read<RideSharingCubit>().bookRide(
                                          vehicleTypeId: selected.id,
                                          pickupLat: _pickupLocation.latitude,
                                          pickupLng: _pickupLocation.longitude,
                                          pickupAddress: _pickupAddress,
                                          dropoffLat: _dropoffLocation.latitude,
                                          dropoffLng: _dropoffLocation.longitude,
                                          dropoffAddress: _dropoffAddress,
                                          paymentMethod: _paymentMethod,
                                          totalFare: estimate.estimatedFare,
                                        );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Confirm & Book Ride',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('Unable to load ride options')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bike':
        return Icons.two_wheeler;
      case 'auto':
        return Icons.electric_rickshaw;
      case 'suv':
        return Icons.directions_car_filled;
      default:
        return Icons.directions_car;
    }
  }
}
