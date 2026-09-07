import 'package:flutter/material.dart';
import '../../../../core/widgets/cached_image.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/datetime_formatter.dart';
import '../../domain/entities/delivery_tracking.dart';

/// Professional Premium-level delivery partner card
/// 
/// Features:
/// - Partner photo with rating
/// - Call and message buttons
/// - Current status indicator
/// - Last update timestamp
/// - Smooth animations
class DeliveryPartnerCard extends StatelessWidget {
  final DeliveryPartner partner;
  final DeliveryLocation? currentLocation;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const DeliveryPartnerCard({
    super.key,
    required this.partner,
    this.currentLocation,
    required this.onCall,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Partner photo
              _buildPartnerPhoto(),

              const SizedBox(width: 12),

              // Partner info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            partner.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildStatusIndicator(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildRating(context),
                    if (currentLocation?.updatedAt != null) ...[
                      const SizedBox(height: 4),
                      _buildLastUpdate(context),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.phone,
                  label: 'Call',
                  onTap: onCall,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.message,
                  label: 'Message',
                  onTap: onMessage,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerPhoto() {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: partner.photo != null
                ? CachedImage(
                    imageUrl: AppConstants.getFullMediaUrl(partner.photo),
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, size: 30),
                    ),
                  )
                : Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
        // Online indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'On the way',
            style: TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.star,
          size: 16,
          color: Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          partner.rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(width: 4),
        Text(
          '• Delivery Partner',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildLastUpdate(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          'Updated ${DateTimeFormatter.timeAgo(currentLocation!.updatedAt!)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
