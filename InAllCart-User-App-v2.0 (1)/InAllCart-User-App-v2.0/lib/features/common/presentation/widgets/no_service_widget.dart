import 'package:flutter/material.dart';
import 'package:inallcart_app/core/theme/app_colors.dart';
import 'package:lottie/lottie.dart';

class NoServiceWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onChangeLocation;

  const NoServiceWidget({
    super.key,
    required this.onRetry,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation (or fallback icon if asset missing)
            SizedBox(
              height: 200,
              width: 200,
              child: Lottie.asset(
                'assets/animations/no_service.json',
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.location_off_outlined, // Fallback icon
                    size: 100,
                    color: AppColors.primary,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "We're not here yet!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Sorry, our services are not available in your current location. Try selecting a different area.",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onChangeLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Change Location",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                "Retry",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
