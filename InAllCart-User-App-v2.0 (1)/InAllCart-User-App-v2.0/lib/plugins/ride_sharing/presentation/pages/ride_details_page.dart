import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../../../features/app_config/domain/entities/app_config.dart';
import '../bloc/ride_sharing_bloc.dart';
import '../bloc/ride_sharing_event.dart';
import '../bloc/ride_sharing_state.dart';
import '../../domain/entities/ride_sharing_entities.dart';
import '../widgets/ride_dialogs.dart';

class RideDetailsPage extends StatelessWidget {
  final int rideId;

  const RideDetailsPage({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<RideSharingBloc>()..add(CheckRideStatusEvent(rideId: rideId)),
      child: _RideDetailsView(rideId: rideId),
    );
  }
}

class _RideDetailsView extends StatelessWidget {
  final int rideId;

  const _RideDetailsView({required this.rideId});

  CurrencyConfig _getCurrencyConfig(BuildContext context) {
    final appConfigState = context.read<AppConfigBloc>().state;
    if (appConfigState is AppConfigLoaded) {
      return appConfigState.config.currencyConfig;
    }
    return const CurrencyConfig(
      defaultCurrency: 'INR',
      symbol: '₹',
      symbolPosition: 'left',
      decimalPlaces: 0,
      thousandSeparator: ',',
      multiCurrencyEnabled: false,
      supportedCurrencies: {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ride Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<RideSharingBloc, RideSharingState>(
        builder: (context, state) {
          if (state is RideSharingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RideSharingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<RideSharingBloc>()
                        .add(CheckRideStatusEvent(rideId: rideId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          Ride? ride;
          if (state is DriverAssigned) {
            ride = state.ride;
          } else if (state is RideSearching) {
            ride = state.ride;
          } else if (state is RideCompleted) {
            ride = state.ride;
          } else if (state is RideTrackingUpdate) {
            ride = state.ride;
          } else if (state is RideCancelled) {
            ride = state.ride;
            // If we somehow don't have the ride object, fall back to a
            // simple cancelled message (no re-fetch — that caused a loop).
            if (ride == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cancel_outlined,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Ride Cancelled',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }
          }

          if (ride == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildDetails(context, ride);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Ride ride) {
    final currency = _getCurrencyConfig(context);
    final driver = ride.driver;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status timeline
          _buildStatusTimeline(ride),
          const SizedBox(height: 20),

          // Cancellation banner (if cancelled)
          if (ride.status == 'cancelled') ...[
            _buildCancellationCard(context, ride),
            const SizedBox(height: 16),
          ],

          // Pickup & Dropoff
          _buildSection(
            title: 'Route',
            child: Column(
              children: [
                _buildLocationRow(
                  color: Colors.green,
                  label: 'Pickup',
                  address: ride.pickupAddress,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Container(
                      height: 20, width: 1.5, color: Colors.grey[300]),
                ),
                _buildLocationRow(
                  color: Colors.red,
                  label: 'Drop-off',
                  address: ride.dropoffAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Trip info (id, distance, duration, timestamps)
          _buildTripInfoSection(ride),
          const SizedBox(height: 16),

          // Driver info
          if (driver != null) ...[
            _buildSection(
              title: 'Driver',
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: driver.photo != null && driver.photo!.isNotEmpty
                        ? Image.network(
                            AppConstants.getFullMediaUrl(driver.photo!),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.grey),
                          )
                        : const Icon(Icons.person,
                            size: 32, color: Colors.grey),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(driver.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12)),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star,
                                      size: 11, color: Colors.black),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${driver.vehicleColor ?? ''} ${driver.vehicleMake ?? ''} ${driver.vehicleModel ?? ''}'
                                  .trim(),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        if (driver.vehiclePlateNumber != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(driver.vehiclePlateNumber!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Emergency SOS & Ride Actions (only during active rides)
          if (['accepted', 'arriving', 'in_progress', 'started', 'driver_arrived']
              .contains(ride.status)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'Emergency SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to alert admin & emergency contacts',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSOSTrigger(context, ride),
                      icon: const Icon(Icons.sos, size: 20),
                      label: const Text('TRIGGER SOS',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Fare breakdown
          _buildSection(
            title: 'Fare Breakdown',
            child: Column(
              children: [
                if (ride.baseFare != null)
                  _buildFareRow('Base Fare', ride.baseFare!, currency),
                if (ride.distanceFare != null)
                  _buildFareRow(
                      'Distance Fare', ride.distanceFare!, currency),
                if (ride.timeFare != null)
                  _buildFareRow('Time Fare', ride.timeFare!, currency),
                if (ride.taxAmount != null)
                  _buildFareRow('Tax', ride.taxAmount!, currency),
                if (ride.discount != null && ride.discount! > 0) ...[
                  _buildFareRow('Discount', -ride.discount!, currency,
                      color: Colors.green),
                  if (ride.promoCode != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text('Promo: ${ride.promoCode}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.green)),
                        ],
                      ),
                    ),
                ],
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      Text(currency.formatAmount(ride.totalFare),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      ride.paymentMethod == 'cash'
                          ? Icons.money
                          : ride.paymentMethod == 'wallet'
                              ? Icons.account_balance_wallet
                              : Icons.payment,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Paid via ${ride.paymentMethod.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rating
          if (ride.rating != null)
            _buildSection(
              title: 'Your Rating',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < ride.rating!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < ride.rating!
                            ? Colors.amber
                            : Colors.grey[300],
                        size: 28,
                      ),
                    ),
                  ),
                  if (ride.ratingComment != null &&
                      ride.ratingComment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('"${ride.ratingComment}"',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handleSOSTrigger(BuildContext context, Ride ride) {
    showSOSConfirmationDialog(
      context: context,
      onConfirm: () async {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          if (context.mounted) {
            context.read<RideSharingBloc>().add(TriggerSOSEvent(
              rideId: ride.id,
              lat: position.latitude,
              lng: position.longitude,
              message: 'Emergency SOS triggered by rider during ride #${ride.id}',
            ));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('🚨 SOS Triggered! Admin has been notified.'),
              backgroundColor: Colors.red,
            ));
          }
        } catch (e) {
          if (context.mounted) {
            context.read<RideSharingBloc>().add(TriggerSOSEvent(
              rideId: ride.id,
              lat: ride.pickupLatitude,
              lng: ride.pickupLongitude,
              message: 'Emergency SOS triggered by rider during ride #${ride.id}',
            ));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('🚨 SOS Triggered! Admin has been notified.'),
              backgroundColor: Colors.red,
            ));
          }
        }
      },
    );
  }

  Widget _buildCancellationCard(BuildContext context, Ride ride) {
    final by = (ride.cancelledBy ?? '').isNotEmpty
        ? ride.cancelledBy![0].toUpperCase() + ride.cancelledBy!.substring(1)
        : 'Someone';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text('Ride Cancelled',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Cancelled by $by',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          if (ride.cancelledAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(_formatDateTime(ride.cancelledAt!),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          if ((ride.cancellationReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('"${ride.cancellationReason}"',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic)),
            ),
          ],
          if (ride.cancellationFee != null && ride.cancellationFee! > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cancellation Fee',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                Text(
                  _getCurrencyConfig(context)
                      .formatAmount(ride.cancellationFee!),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.red),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripInfoSection(Ride ride) {
    final rows = <Widget>[
      _infoRow('Ride ID', '#${ride.id}'),
      _infoRow('Payment', ride.paymentMethod.toUpperCase()),
      if ((ride.paymentStatus ?? '').isNotEmpty)
        _infoRow('Payment Status', ride.paymentStatus!.toUpperCase()),
      if (ride.distanceKm != null && ride.distanceKm! > 0)
        _infoRow('Distance', '${ride.distanceKm!.toStringAsFixed(1)} km'),
      if (ride.durationMinutes != null && ride.durationMinutes! > 0)
        _infoRow('Duration', '${ride.durationMinutes} min'),
      if (ride.createdAt != null)
        _infoRow('Booked', _formatDateTime(ride.createdAt!)),
      if (ride.completedAt != null)
        _infoRow('Completed', _formatDateTime(ride.completedAt!)),
    ];
    return _buildSection(
      title: 'Trip Info',
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final ap = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day} ${months[d.month - 1]} ${d.year}, $h:${d.minute.toString().padLeft(2, '0')} $ap';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildStatusTimeline(Ride ride) {
    final statuses = [
      'searching',
      'assigned',
      'arriving',
      'arrived',
      'started',
      'completed'
    ];
    final currentIndex =
        statuses.indexOf(ride.status).clamp(0, statuses.length - 1);
    final isCancelled = ride.status == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.red.withOpacity(0.1)
                      : ride.status == 'completed'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ride.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCancelled
                        ? Colors.red
                        : ride.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (!isCancelled) ...[
            const SizedBox(height: 16),
            Row(
              children: List.generate(statuses.length, (index) {
                final isActive = index <= currentIndex;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                        right: index < statuses.length - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.amber : Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required Color color,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(address,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareRow(String label, double amount, CurrencyConfig currency,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: color ?? Colors.black54)),
          Text(
            currency.formatAmount(amount),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}
