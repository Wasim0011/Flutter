import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_config.dart';

class InAppUpdateDialog extends StatelessWidget {
  final AppConfig config;

  const InAppUpdateDialog({super.key, required this.config});

  static Future<void> checkAndShow(BuildContext context, AppConfig config) async {
    final minVer = config.minAppVersion;
    final latestVer = config.latestAppVersion;
    final force = config.forceUpdate;

    if (minVer == null && latestVer == null) return;

    // Simple semver check
    final currentVersion = config.appVersion;
    final needsMinUpdate = minVer != null && _isVersionLower(currentVersion, minVer);
    final needsLatestUpdate = latestVer != null && _isVersionLower(currentVersion, latestVer);

    if (needsMinUpdate || needsLatestUpdate) {
      final isForce = force || needsMinUpdate;
      await showDialog<void>(
        context: context,
        barrierDismissible: !isForce,
        builder: (ctx) => InAppUpdateDialog(
          config: AppConfig(
            onboardingEnabled: config.onboardingEnabled,
            onboardingScreens: config.onboardingScreens,
            mapProvider: config.mapProvider,
            pushNotificationConfig: config.pushNotificationConfig,
            appName: config.appName,
            appVersion: config.appVersion,
            currencyConfig: config.currencyConfig,
            timezoneConfig: config.timezoneConfig,
            minAppVersion: minVer,
            latestAppVersion: latestVer,
            forceUpdate: isForce,
            playStoreUrl: config.playStoreUrl,
            appStoreUrl: config.appStoreUrl,
          ),
        ),
      );
    }
  }

  static bool _isVersionLower(String current, String target) {
    try {
      final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final tParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final t = i < tParts.length ? tParts[i] : 0;
        if (c < t) return true;
        if (c > t) return false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _launchStore() async {
    final String defaultPlayUrl = 'https://play.google.com/store/apps/details?id=com.inallcart.app';
    final String defaultAppStoreUrl = 'https://apps.apple.com/app/inallcart/id123456789';

    final urlStr = Platform.isIOS
        ? (config.appStoreUrl ?? defaultAppStoreUrl)
        : (config.playStoreUrl ?? defaultPlayUrl);

    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isForce = config.forceUpdate;

    return PopScope(
      canPop: !isForce,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isForce ? 'Critical Update Required' : 'New Update Available',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isForce
                    ? 'Please update ${config.appName} to the latest version to continue using the app.'
                    : 'A new version of ${config.appName} is available with fresh features and performance improvements.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _launchStore,
                  child: const Text(
                    'UPDATE NOW',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (!isForce) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
