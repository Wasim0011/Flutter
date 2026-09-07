import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../../../features/app_config/domain/entities/app_config.dart';
import '../bloc/ride_sharing_bloc.dart';
import '../bloc/ride_sharing_event.dart';
import '../bloc/ride_sharing_state.dart';
import '../../domain/entities/ride_sharing_entities.dart';
import '../theme/ride_colors.dart';

class RideRatingPage extends StatelessWidget {
  final Ride ride;

  const RideRatingPage({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RideSharingBloc>(),
      child: _RideRatingView(ride: ride),
    );
  }
}

class _RideRatingView extends StatefulWidget {
  final Ride ride;

  const _RideRatingView({required this.ride});

  @override
  State<_RideRatingView> createState() => _RideRatingViewState();
}

class _RideRatingViewState extends State<_RideRatingView> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  CurrencyConfig _getCurrencyConfig() {
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
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.ride.driver;
    final currency = _getCurrencyConfig();

    return BlocListener<RideSharingBloc, RideSharingState>(
      listener: (context, state) {
        if (state is RideRated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Thank you for your feedback!'),
                backgroundColor: Colors.green),
          );
          context.pop(true);
        } else if (state is RideSharingError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is RideSharingLoading) {
          setState(() => _isSubmitting = true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Rate your ride',
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Driver info
              if (driver != null) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: driver.photo != null && driver.photo!.isNotEmpty
                      ? Image.network(
                          AppConstants.getFullMediaUrl(driver.photo!),
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.person,
                              size: 48, color: Colors.grey),
                        )
                      : const Icon(Icons.person,
                          size: 48, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(driver.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '${driver.vehicleColor ?? ''} ${driver.vehicleMake ?? ''} ${driver.vehicleModel ?? ''}'
                      .trim(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (driver.vehiclePlateNumber != null)
                  Text(driver.vehiclePlateNumber!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600)),
              ],

              const SizedBox(height: 24),

              // Fare summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Fare',
                        style: TextStyle(
                            fontSize: 16, color: Colors.black54)),
                    Text(currency.formatAmount(widget.ride.totalFare),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Star rating
              const Text('How was your ride?',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        starIndex <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 48,
                        color: starIndex <= _rating
                            ? Colors.amber
                            : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: 8),
                Text(
                  _getRatingLabel(_rating),
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500),
                ),
              ],

              const SizedBox(height: 24),

              // Comment field
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: RideColors.accent, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_rating == 0 || _isSubmitting)
                      ? null
                      : () {
                          context.read<RideSharingBloc>().add(
                                RateRideEvent(
                                  rideId: widget.ride.id,
                                  rating: _rating,
                                  comment: _commentController.text.isNotEmpty
                                      ? _commentController.text
                                      : null,
                                ),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RideColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: Colors.grey[200],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Rating',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),

              const SizedBox(height: 12),

              // Skip button
              TextButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
                child: const Text('Skip',
                    style: TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Below Average';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
