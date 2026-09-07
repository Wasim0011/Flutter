import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/ride_models.dart';
import '../../data/repositories/ride_sharing_repository.dart';
import '../../../../core/di/injection.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  late Future<List<RideBookingModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = getIt<RideSharingRepository>().getRideHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Ride History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<RideBookingModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // M-5 FIX: Handle error state explicitly instead of showing empty
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Failed to load ride history',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Please check your internet connection and try again',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadHistory();
                      });
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Retry', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            );
          }

          final rides = snapshot.data ?? [];
          if (rides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_taxi_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No rides booked yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Your past taxi rides will appear here',
                      style: TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/ride-sharing'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Book a Ride Now', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadHistory();
              });
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ride = rides[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // U-4 FIX: Show ride number, fare, date, and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ride.rideNumber,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                if (ride.createdAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      _formatDate(ride.createdAt!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${ride.totalFare.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary)),
                              const SizedBox(height: 4),
                              _buildStatusChip(ride.status),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      // Driver info
                      if (ride.driverName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: Color(0xFF6B7280)),
                              const SizedBox(width: 6),
                              Text(ride.driverName!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                              if (ride.vehicleNumber != null) ...[
                                const Text(' • ', style: TextStyle(color: Color(0xFF6B7280))),
                                Text(ride.vehicleNumber!,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                              ],
                            ],
                          ),
                        ),
                      // Addresses
                      Row(
                        children: [
                          const Icon(Icons.circle, color: Colors.green, size: 10),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ride.pickupAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.square, color: Colors.red, size: 10),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ride.dropoffAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        label = 'Cancelled';
        break;
      case 'in_transit':
      case 'started':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        label = 'In Transit';
        break;
      default:
        bg = Colors.orange.shade50;
        text = Colors.orange.shade700;
        label = status.replaceAll('_', ' ').toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return dateStr;
    }
  }
}
