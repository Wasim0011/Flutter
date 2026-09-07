import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/utils/datetime_formatter.dart';

/// Professional Premium-level ETA countdown widget
/// 
/// Features:
/// - Real-time countdown
/// - Color-coded urgency
/// - Smooth animations
/// - Estimated delivery time
class EtaCountdownWidget extends StatefulWidget {
  final int etaMinutes;
  final DateTime? estimatedDeliveryAt;

  const EtaCountdownWidget({
    super.key,
    required this.etaMinutes,
    this.estimatedDeliveryAt,
  });

  @override
  State<EtaCountdownWidget> createState() => _EtaCountdownWidgetState();
}

class _EtaCountdownWidgetState extends State<EtaCountdownWidget> {
  Timer? _countdownTimer;
  int _remainingMinutes = 0;

  @override
  void initState() {
    super.initState();
    _remainingMinutes = widget.etaMinutes;
    _startCountdown();
  }

  @override
  void didUpdateWidget(EtaCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.etaMinutes != oldWidget.etaMinutes) {
      _remainingMinutes = widget.etaMinutes;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        if (_remainingMinutes > 0) {
          setState(() {
            _remainingMinutes--;
          });
        }
      },
    );
  }

  Color _getUrgencyColor() {
    if (_remainingMinutes <= 10) {
      return Colors.red;
    } else if (_remainingMinutes <= 20) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getUrgencyIcon() {
    if (_remainingMinutes <= 10) {
      return Icons.bolt;
    } else if (_remainingMinutes <= 20) {
      return Icons.directions_bike;
    } else {
      return Icons.schedule;
    }
  }

  String _getEtaText() {
    if (_remainingMinutes <= 0) {
      return 'Arriving soon';
    } else if (_remainingMinutes == 1) {
      return '1 min';
    } else {
      return '$_remainingMinutes mins';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ETA with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getUrgencyIcon(),
                  size: 18,
                  color: urgencyColor,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getEtaText(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: urgencyColor,
                        ),
                  ),
                  Text(
                    'Estimated time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),

          // Estimated delivery time
          if (widget.estimatedDeliveryAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Arriving at ${DateTimeFormatter.formatTimeStatic(widget.estimatedDeliveryAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
