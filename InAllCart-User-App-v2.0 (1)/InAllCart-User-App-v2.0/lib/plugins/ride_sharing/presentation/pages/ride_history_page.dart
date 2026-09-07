import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../../../features/app_config/domain/entities/app_config.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/widgets/unauthenticated_widget.dart';
import '../bloc/ride_sharing_bloc.dart';
import '../bloc/ride_sharing_event.dart';
import '../bloc/ride_sharing_state.dart';
import '../../domain/entities/ride_sharing_entities.dart';

class RideHistoryPage extends StatelessWidget {
  const RideHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RideSharingBloc>()..add(const LoadRideHistoryEvent()),
      child: const _RideHistoryView(),
    );
  }
}

class _RideHistoryView extends StatefulWidget {
  const _RideHistoryView();

  @override
  State<_RideHistoryView> createState() => _RideHistoryViewState();
}

class _RideHistoryViewState extends State<_RideHistoryView> {
  final List<Ride> _rides = [];
  bool _hasMore = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoadingMore) {
      _isLoadingMore = true;
      context
          .read<RideSharingBloc>()
          .add(LoadRideHistoryEvent(page: _currentPage + 1));
    }
  }

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
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: authState is Unauthenticated
          ? Center(
              child: UnauthenticatedWidget(
                onLoginSuccess: () {
                  context.read<RideSharingBloc>().add(const LoadRideHistoryEvent());
                },
              ),
            )
          : BlocConsumer<RideSharingBloc, RideSharingState>(
        listener: (context, state) {
          if (state is RideHistoryLoaded) {
            setState(() {
              if (state.currentPage == 1) {
                _rides.clear();
              }
              _rides.addAll(state.rides);
              _hasMore = state.hasMore;
              _currentPage = state.currentPage;
              _isLoadingMore = false;
            });
          }
        },
        builder: (context, state) {

          if (state is RideSharingLoading && _rides.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RideSharingError && _rides.isEmpty) {
            if (state.message.toLowerCase().contains('unauthenticated') ||
                state.message.contains('401')) {
              return Center(
                child: UnauthenticatedWidget(
                  onLoginSuccess: () {
                    context.read<RideSharingBloc>().add(const LoadRideHistoryEvent());
                  },
                ),
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<RideSharingBloc>()
                        .add(const LoadRideHistoryEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_rides.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<RideSharingBloc>()
                  .add(const LoadRideHistoryEvent());
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _rides.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _rides.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildRideCard(_rides[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No rides yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          Text('Your ride history will appear here',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    final currency = _getCurrencyConfig();
    final statusColor = _getStatusColor(ride.status);

    return InkWell(
      onTap: () {
        context.push('/ride-sharing/details/${ride.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: status + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ride.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ),
                if (ride.createdAt != null)
                  Text(
                    _formatDate(ride.createdAt!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup → Dropoff
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle)),
                    Container(
                        height: 20, width: 1.5, color: Colors.grey[300]),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.pickupAddress,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Text(ride.dropoffAddress,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1)),

            // Bottom: vehicle type + fare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      ride.vehicleTypeName ?? 'Ride',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
                Text(
                  currency.formatAmount(ride.totalFare),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'started':
        return Colors.blue;
      case 'searching':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return dateStr;
    }
  }
}
