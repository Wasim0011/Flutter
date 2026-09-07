import 'package:flutter/material.dart';
import '../../../../features/app_config/domain/entities/app_config.dart';
import '../../domain/entities/ride_sharing_entities.dart';
import '../theme/ride_colors.dart';

/// Shows the ride completed dialog with fare summary and rate/skip actions.
void showRideCompletedDialog({
  required BuildContext context,
  required Ride ride,
  required CurrencyConfig currency,
  required VoidCallback onRate,
  required VoidCallback onSkip,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 40, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              'Trip Completed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thank you for riding with us',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),

            // Fare row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Fare',
                          style: TextStyle(
                              fontSize: 13, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(
                        currency.formatAmount(ride.totalFare),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
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
                          ride.paymentMethod.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Rate button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onRate();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RideColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Rate your ride',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Skip
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onSkip();
              },
              child: Text(
                'Skip',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shows the SOS confirmation dialog.
void showSOSConfirmationDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 36, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'Emergency SOS',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'This will alert the admin and emergency contacts with your current location.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Trigger SOS',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PromoCodeDialog extends StatefulWidget {
  final String? currentCode;
  final ValueChanged<String?> onApply;

  const _PromoCodeDialog({
    required this.currentCode,
    required this.onApply,
  });

  @override
  State<_PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends State<_PromoCodeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promo Code',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'ENTER CODE',
                hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.normal,
                    letterSpacing: 1),
                prefixIcon: const Icon(Icons.local_offer_outlined,
                    color: Colors.black54),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: RideColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final code = _controller.text.trim();
                      Navigator.pop(context);
                      widget.onApply(code.isNotEmpty ? code : null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RideColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the promo code input dialog.
void showPromoCodeDialog({
  required BuildContext context,
  String? currentCode,
  required ValueChanged<String?> onApply,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => _PromoCodeDialog(
      currentCode: currentCode,
      onApply: onApply,
    ),
  );
}

/// Shows the payment method picker bottom sheet.
void showPaymentMethodPicker({
  required BuildContext context,
  required String currentMethod,
  required List<PaymentMethodInfo> availableMethods,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Payment Method',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _PaymentOption(
              icon: Icons.money,
              label: 'Cash',
              subtitle: 'Pay after the ride',
              color: Colors.green,
              isSelected: currentMethod == 'cash',
              onTap: () {
                Navigator.pop(sheetContext);
                onSelected('cash');
              },
            ),
            _PaymentOption(
              icon: Icons.account_balance_wallet,
              label: 'Wallet',
              subtitle: 'Pay from your balance',
              color: Colors.blue,
              isSelected: currentMethod == 'wallet',
              onTap: () {
                Navigator.pop(sheetContext);
                onSelected('wallet');
              },
            ),
            if (availableMethods.any(
                (m) => m.id != 'cash' && m.id != 'wallet'))
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1),
              ),
            // Online gateways only — Cash & Wallet are shown explicitly above,
            // so exclude them here to avoid duplicates.
            ...availableMethods
                .where((m) => m.id != 'cash' && m.id != 'wallet')
                .map((method) => _PaymentOption(
                      icon: Icons.payment,
                      label: method.name,
                      subtitle: 'Online payment',
                      color: Colors.orange,
                      isSelected: currentMethod == method.id,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSelected(method.id);
                      },
                    )),
          ],
        ),
      );
    },
  );
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: Colors.black87, size: 22)
          : null,
    );
  }
}
