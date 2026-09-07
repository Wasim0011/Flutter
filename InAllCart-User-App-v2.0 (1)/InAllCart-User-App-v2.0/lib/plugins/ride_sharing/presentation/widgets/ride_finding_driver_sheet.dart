import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/ride_colors.dart';

/// Bottom sheet shown while searching for a nearby driver.
/// Displays a 5-minute countdown timer, animated search indicator,
/// price boost buttons (+10, +15, +20, +50), and cancel button.
class RideFindingDriverSheet extends StatefulWidget {
  final int? rideId;
  final bool isCancelling;
  final double currentFare;
  final String currencySymbol;
  final VoidCallback onCancel;
  final ValueChanged<double> onPriceBoost;
  final VoidCallback onTimeout;

  const RideFindingDriverSheet({
    super.key,
    this.rideId,
    required this.isCancelling,
    required this.currentFare,
    this.currencySymbol = '\u20B9',
    required this.onCancel,
    required this.onPriceBoost,
    required this.onTimeout,
  });

  @override
  State<RideFindingDriverSheet> createState() => _RideFindingDriverSheetState();
}

class _RideFindingDriverSheetState extends State<RideFindingDriverSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  /// 5-minute countdown (300 seconds)
  static const int _totalSeconds = 300;
  int _remainingSeconds = _totalSeconds;
  Timer? _countdownTimer;

  /// Accumulated price boost
  double _totalBoost = 0;

  @override
  void initState() {
    super.initState();

    // Pulse animation for search indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start 5-minute countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _displayFare => widget.currentFare + _totalBoost;

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / _totalSeconds;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // -- Countdown timer ring with animated search indicator --
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 4,
                    color: Colors.grey.shade200,
                  ),
                ),
                // Countdown progress ring
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    color: progress > 0.3
                        ? RideColors.accent
                        : Colors.redAccent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Pulsing inner indicator
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          RideColors.accent.withOpacity(0.25),
                          RideColors.primary.withOpacity(0.15),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: RideColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // -- Timer display --
          Text(
            _formatTime(_remainingSeconds),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: _remainingSeconds > 60
                  ? Colors.black87
                  : Colors.redAccent,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 6),

          // -- Status text with animated dots --
          Builder(
            builder: (context) {
              final dotCount = (_remainingSeconds % 3) + 1;
              final dots = '.' * dotCount;
              return Text(
                'Finding your captain$dots',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              );
            },
          ),

          const SizedBox(height: 2),

          Text(
            'Matching you with the nearest driver',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),

          // -- Ride number + fare badge --
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.rideId != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ride #${widget.rideId}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              if (widget.rideId != null) const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: RideColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.currencySymbol}${_displayFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: RideColors.primary,
                  ),
                ),
              ),
              if (_totalBoost > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${widget.currencySymbol}${_totalBoost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // -- Price boost section --
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE0A0), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Increase fare to find driver faster',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildBoostButton(10),
                    const SizedBox(width: 8),
                    _buildBoostButton(15),
                    const SizedBox(width: 8),
                    _buildBoostButton(20),
                    const SizedBox(width: 8),
                    _buildBoostButton(50),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // -- Cancel button --
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.isCancelling ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: widget.isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.red, strokeWidth: 2))
                  : const Text(
                      'Cancel Ride',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostButton(double amount) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            setState(() {
              _totalBoost += amount;
              // Reset timer to give more search time on boost
              _remainingSeconds = _totalSeconds;
            });
            widget.onPriceBoost(amount);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: RideColors.accent.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '+${widget.currencySymbol}${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: RideColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
