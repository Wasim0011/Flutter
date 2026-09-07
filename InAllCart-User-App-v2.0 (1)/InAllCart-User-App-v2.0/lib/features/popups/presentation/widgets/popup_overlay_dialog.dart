import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../domain/entities/popup.dart';

class PopupOverlayDialog extends StatelessWidget {
  final PopupEntity popup;

  const PopupOverlayDialog({
    super.key,
    required this.popup,
  });

  static Future<void> show(BuildContext context, PopupEntity popup) async {
    final delaySeconds = int.tryParse(popup.triggerValue) ?? 0;
    if (popup.displayTrigger == 'after_x_seconds' && delaySeconds > 0) {
      await Future.delayed(Duration(seconds: delaySeconds));
    }

    if (!context.mounted) return;

    // Use non-blocking Overlay for top, bottom, and floating popups so user can continue scrolling & using app
    if (popup.position == 'top' || popup.position == 'bottom' || popup.position == 'floating') {
      final overlay = Overlay.of(context);
      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (overlayContext) => _NonBlockingPopupOverlay(
          popup: popup,
          onClose: () => entry.remove(),
        ),
      );

      overlay.insert(entry);
      return;
    }

    if (popup.position == 'full_screen') {
      return showGeneralDialog<void>(
        context: context,
        barrierDismissible: popup.showCloseButton,
        barrierLabel: 'Popup',
        barrierColor: Colors.black,
        pageBuilder: (context, anim1, anim2) => PopupOverlayDialog(popup: popup),
      );
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: popup.showCloseButton,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => PopupOverlayDialog(popup: popup),
    );
  }

  void _handleImageClick(BuildContext context) async {
    final action = popup.clickAction;
    final target = popup.clickActionTarget;

    // Dismiss popup before executing action
    Navigator.of(context, rootNavigator: true).pop();

    if (action == 'none' || action.isEmpty) {
      return;
    }

    try {
      if (action == 'url' && target.isNotEmpty) {
        final uri = Uri.parse(target);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (action == 'page' && target.isNotEmpty) {
        context.push(target);
      } else if (action == 'product' && target.isNotEmpty) {
        context.push(Routes.product(target));
      } else if (action == 'category' && target.isNotEmpty) {
        context.push(Routes.category(target));
      } else if (action == 'store' && target.isNotEmpty) {
        context.push(Routes.store(target));
      } else if (action == 'coupon') {
        context.push(Routes.cart);
      } else if (action == 'membership') {
        context.push(Routes.vipMembership);
      }
    } catch (e) {
      debugPrint('[POPUP_CLICK_ERROR] Failed to execute click action $action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      child: Material(
        color: Colors.transparent,
        child: _buildCenterLayout(context, size),
      ),
    );
  }

  Widget _buildCenterLayout(BuildContext context, Size size) {
    return Center(
      child: SingleChildScrollView(
        child: _buildMediaCard(
          context,
          size,
          width: size.width * 0.85,
          height: size.height * 0.5,
        ),
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, Size size, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GestureDetector(
                onTap: () => _handleImageClick(context),
                child: CachedImage(
                  imageUrl: popup.mediaUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (popup.showCloseButton)
            Positioned(
              top: 12,
              right: 12,
              child: _buildCloseButton(context),
            ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// Non-blocking floating/top/bottom overlay widget that allows full app interaction behind it
class _NonBlockingPopupOverlay extends StatelessWidget {
  final PopupEntity popup;
  final VoidCallback onClose;

  const _NonBlockingPopupOverlay({
    required this.popup,
    required this.onClose,
  });

  void _handleImageClick(BuildContext context) async {
    final action = popup.clickAction;
    final target = popup.clickActionTarget;

    onClose();

    if (action == 'none' || action.isEmpty) return;

    try {
      if (action == 'url' && target.isNotEmpty) {
        final uri = Uri.parse(target);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (action == 'page' && target.isNotEmpty) {
        context.push(target);
      } else if (action == 'product' && target.isNotEmpty) {
        context.push(Routes.product(target));
      } else if (action == 'category' && target.isNotEmpty) {
        context.push(Routes.category(target));
      } else if (action == 'store' && target.isNotEmpty) {
        context.push(Routes.store(target));
      } else if (action == 'coupon') {
        context.push(Routes.cart);
      } else if (action == 'membership') {
        context.push(Routes.vipMembership);
      }
    } catch (e) {
      debugPrint('[POPUP_CLICK_ERROR] Failed to execute click action $action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget card;
    if (popup.position == 'top') {
      card = SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: _buildCard(context, size, width: size.width * 0.9, height: 130),
          ),
        ),
      );
    } else if (popup.position == 'bottom') {
      card = SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 75.0),
            child: _buildCard(context, size, width: size.width * 0.9, height: 130),
          ),
        ),
      );
    } else {
      // 'floating' - Sleek floating popup card positioned lower
      card = SafeArea(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 14.0, bottom: 25.0),
            child: _buildCard(context, size, width: 140, height: 140),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: card,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, Size size, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () => _handleImageClick(context),
                child: CachedImage(
                  imageUrl: popup.mediaUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (popup.showCloseButton)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
