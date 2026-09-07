
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _storage = getIt<StorageService>();
  late List<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _storage.getNotifications();
    // Mark all as read when page opens
    _storage.markAllNotificationsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: GlobalAppBar(
        title: 'Notifications',
        actions: _notifications.isNotEmpty
            ? [
                TextButton(
                  onPressed: _clearAll,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _notifications.isEmpty ? _buildEmpty() : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We'll notify you when something arrives",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final n = _notifications[index];
        return _NotificationTile(
          notification: n,
          onTap: () => _handleTap(n),
          onDismiss: () => _dismiss(index),
        );
      },
    );
  }

  void _handleTap(Map<String, dynamic> n) {
    final data = n['data'] as Map<String, dynamic>? ?? {};
    final orderId = data['order_id'] ?? data['orderId'] ?? n['order_id'] ?? n['orderId'];
    if (orderId != null) {
      context.push('/orders/$orderId');
      return;
    }
    final type = data['type'] as String? ?? n['type'] as String? ?? '';
    if (type.contains('order') || type.contains('delivery') || type.contains('ride')) {
      context.go('/orders');
      return;
    }
    if (data.isNotEmpty) {
      DeepLinkService.handleDeepLink(data, GoRouter.of(context));
    } else {
      context.go('/orders');
    }
  }

  void _dismiss(int index) {
    final list = _storage.getNotifications();
    list.removeAt(index);
    _storage.saveRawNotifications(list);
    setState(() => _notifications = list);
  }

  void _clearAll() async {
    await _storage.clearNotifications();
    setState(() => _notifications = []);
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? true;
    final receivedAt = notification['receivedAt'] as String?;
    final timeLabel = receivedAt != null ? _formatTime(receivedAt) : '';
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final type = data['type'] as String? ?? '';

    return Dismissible(
      key: Key(notification['id'] as String? ?? title),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.04),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconBg(type),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(type), color: _iconColor(type), size: 22),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        timeLabel,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order_status':
        return Icons.shopping_bag_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'product':
        return Icons.inventory_2_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBg(String type) {
    switch (type) {
      case 'order_status':
        return const Color(0xFFFFF3E0);
      case 'promotion':
        return const Color(0xFFFCE4EC);
      case 'product':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFEDE7F6);
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'order_status':
        return Colors.orange;
      case 'promotion':
        return Colors.pink;
      case 'product':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return '';
    }
  }
}
