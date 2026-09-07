import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/datetime_formatter.dart';

/// Professional Premium-level order status timeline
/// 
/// Features:
/// - Visual timeline with checkmarks
/// - Current status highlighted
/// - Timestamps for completed steps
/// - Smooth animations
class OrderStatusTimelineWidget extends StatelessWidget {
  final String orderNumber;
  final String status;
  final DateTime? estimatedDeliveryAt;

  const OrderStatusTimelineWidget({
    super.key,
    required this.orderNumber,
    required this.status,
    this.estimatedDeliveryAt,
  });

  List<TimelineStep> _getTimelineSteps() {
    return [
      TimelineStep(
        title: 'Order Confirmed',
        subtitle: 'Your order has been confirmed',
        icon: Icons.check_circle,
        isCompleted: _isStepCompleted('confirmed'),
        isCurrent: status == 'confirmed',
      ),
      TimelineStep(
        title: 'Packed',
        subtitle: 'Store has packed your order',
        icon: Icons.inventory_2,
        isCompleted: _isStepCompleted('packed'),
        isCurrent: status == 'packed',
      ),
      TimelineStep(
        title: 'Picked Up',
        subtitle: 'Driver has picked up your order',
        icon: Icons.local_shipping,
        isCompleted: _isStepCompleted('picked_up'),
        isCurrent: status == 'picked_up',
      ),
      TimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Your order is on the way',
        icon: Icons.delivery_dining,
        isCompleted: _isStepCompleted('out_for_delivery'),
        isCurrent: status == 'out_for_delivery',
      ),
      TimelineStep(
        title: 'Delivered',
        subtitle: estimatedDeliveryAt != null
            ? 'Est. ${DateTimeFormatter.formatTimeStatic(estimatedDeliveryAt!)}'
            : 'Order will be delivered',
        icon: Icons.home,
        isCompleted: _isStepCompleted('delivered'),
        isCurrent: status == 'delivered',
      ),
    ];
  }

  bool _isStepCompleted(String stepStatus) {
    const statusOrder = [
      'pending',
      'confirmed',
      'packed',
      'picked_up',
      'out_for_delivery',
      'delivered',
    ];

    final currentIndex = statusOrder.indexOf(status);
    final stepIndex = statusOrder.indexOf(stepStatus);

    return currentIndex >= stepIndex;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getTimelineSteps();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Order #$orderNumber',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timeline
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;

            return _buildTimelineItem(
              context: context,
              step: step,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required TimelineStep step,
    required bool isLast,
  }) {
    final color = step.isCompleted
        ? AppColors.primary
        : step.isCurrent
            ? Colors.orange
            : Colors.grey[400]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            // Circle with icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: step.isCompleted || step.isCurrent
                    ? color.withValues(alpha: 0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                step.isCompleted ? Icons.check : step.icon,
                size: 18,
                color: color,
              ),
            ),

            // Connecting line
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: step.isCompleted ? color : Colors.grey[300],
              ),
          ],
        ),

        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: step.isCurrent || step.isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: step.isCompleted || step.isCurrent
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
  });
}
