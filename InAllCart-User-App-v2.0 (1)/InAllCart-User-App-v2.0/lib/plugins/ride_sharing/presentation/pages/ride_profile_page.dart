import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/router/routes.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/support/presentation/screens/support_tickets_screen.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../theme/ride_colors.dart';

/// Dedicated profile screen for the ride-sharing experience, themed in the
/// plugin's black + yellow palette (independent of the host app's profile UI).
class RideProfilePage extends StatefulWidget {
  final ValueChanged<int>? onSelectTab;

  const RideProfilePage({super.key, this.onSelectTab});

  @override
  State<RideProfilePage> createState() => _RideProfilePageState();
}

class _RideProfilePageState extends State<RideProfilePage> {
  int? _activeSosId;
  bool _hasActiveRide = false;

  @override
  void initState() {
    super.initState();
    _checkActiveSos();
    _checkActiveRide();
  }

  Future<void> _checkActiveRide() async {
    try {
      final apiClient = getIt<ApiClient>();
      final res = await apiClient.get<Map<String, dynamic>>('/api/v1/rides/active');
      if (mounted) {
        final data = res;
        final hasRide = data != null &&
            data['success'] == true &&
            data['data'] != null &&
            data['data']['status'] != null &&
            ['accepted', 'arriving', 'in_progress', 'started', 'driver_arrived']
                .contains(data['data']['status']);
        setState(() => _hasActiveRide = hasRide);
      }
    } catch (_) {
      if (mounted) setState(() => _hasActiveRide = false);
    }
  }

  Future<void> _checkActiveSos() async {
    try {
      final apiClient = getIt<ApiClient>();
      final res = await apiClient.get<Map<String, dynamic>>('/api/v1/sos/active');
      if (res['success'] == true && res['data'] != null) {
        if (mounted) {
          setState(() {
            _activeSosId = res['data']['id'] as int?;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _activeSosId = null;
      });
    }
  }

  Future<void> _makeCall(BuildContext context) async {
    final supportPhone = getIt<AppConfigBloc>().currentConfig?.supportPhone;
    if (supportPhone == null || supportPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support phone number is not configured.')),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone.replaceAll(RegExp(r'\s+'), ''));
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch dialer.';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to make a call: $e')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final supportPhone = getIt<AppConfigBloc>().currentConfig?.supportPhone;
    if (supportPhone == null || supportPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp number is not configured.')),
      );
      return;
    }
    final cleanPhone = supportPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanPhone");
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open WhatsApp app.';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open WhatsApp: $e')),
        );
      }
    }
  }

  Future<void> _triggerGlobalSOS(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🚨 Trigger Emergency SOS?'),
        content: const Text(
          'This will notify the administration and send alerts to your configured emergency contact list containing your live location trail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('TRIGGER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final apiClient = getIt<ApiClient>();
        final position = await getIt<LocationService>().getCurrentLocation();
        if (position == null) {
          throw Exception("Unable to retrieve current location.");
        }
        
        final res = await apiClient.post<Map<String, dynamic>>(
          '/api/v1/sos/trigger',
          data: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'message': 'Emergency alarm triggered by User from taxi profile menu.',
          },
        );

        if (res['success'] == true && context.mounted) {
          final eventId = res['data']['id'] as int;
          _checkActiveSos();
          context.push('/active-sos', extra: {'sosEventId': eventId});
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to trigger SOS: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;
          final name = user?.name ?? 'Guest';
          final phone = user?.phone ?? user?.email ?? '';
          final initial =
              name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'G';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(context, name, phone, initial, user?.avatar),
              const SizedBox(height: 16),

              _menuGroup([
                _MenuItem(
                  icon: Icons.receipt_long_rounded,
                  iconBg: const Color(0xFFFFF8E1),
                  iconColor: RideColors.primary,
                  title: 'My Rides',
                  onTap: () => widget.onSelectTab?.call(1),
                ),
                _MenuItem(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: const Color(0xFFFFF8E1),
                  iconColor: RideColors.primary,
                  title: 'Wallet',
                  onTap: () => widget.onSelectTab?.call(2),
                ),
                _MenuItem(
                  icon: Icons.location_on_rounded,
                  iconBg: const Color(0xFFFEF3F2),
                  iconColor: const Color(0xFFEF4444),
                  title: 'Saved Addresses',
                  onTap: () => context.push(Routes.addresses),
                ),
              ]),

              const SizedBox(height: 16),

              _menuGroup([
                _MenuItem(
                  icon: Icons.notifications_rounded,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Notifications',
                  onTap: () => context.push(Routes.notifications),
                ),
                _MenuItem(
                  icon: Icons.edit_outlined,
                  iconBg: const Color(0xFFF5F3FF),
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Edit Profile',
                  onTap: () => context.push(Routes.editProfile),
                ),
                _MenuItem(
                  icon: Icons.support_agent_rounded,
                  iconBg: const Color(0xFFF0FDF4),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Help & Support',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SupportTicketsScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              _menuGroup([
                _MenuItem(
                  icon: Icons.contacts_rounded,
                  iconBg: const Color(0xFFFFFBEB),
                  iconColor: const Color(0xFFD97706),
                  title: 'Add Emergency Contacts',
                  onTap: () async {
                    await context.push('/emergency-contacts');
                    _checkActiveSos();
                  },
                ),
                if (_hasActiveRide) ...[
                  _MenuItem(
                    icon: Icons.emergency,
                    iconBg: const Color(0xFFFEF3F2),
                    iconColor: const Color(0xFFDC2626),
                    title: 'Emergency SOS',
                    onTap: () => _triggerGlobalSOS(context),
                  ),
                  _MenuItem(
                    icon: Icons.phone_in_talk_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    title: 'SOS Call',
                    onTap: () => _makeCall(context),
                  ),
                ],
                _MenuItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  title: 'WhatsApp Support',
                  onTap: () => _openWhatsApp(context),
                ),
              ]),

              const SizedBox(height: 24),

              // Login / Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: state is Authenticated
                      ? OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(Icons.logout_rounded,
                              size: 20, color: Color(0xFFDC2626)),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.login_rounded,
                              size: 20, color: Colors.white),
                          label: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RideColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, String name, String phone,
      String initial, String? avatar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
      decoration: const BoxDecoration(
        gradient: RideColors.darkGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: RideColors.accent.withOpacity(0.6), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? NetworkImage(avatar)
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: RideColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(Routes.editProfile),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: RideColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: RideColors.onAccent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuGroup(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1)
              const Divider(height: 1, indent: 64, color: Color(0xFFF2F2F2)),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      context.read<AuthBloc>().add(LogoutEvent());
    }
  }
}

// ── Pulsing Ring Widget for Active SOS ────────────────────────────────
class PulsingRing extends StatefulWidget {
  const PulsingRing({super.key});

  @override
  State<PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(1.0 - _controller.value),
            border: Border.all(
              color: Colors.red.withOpacity(1.0 - _controller.value),
              width: 4 * _controller.value,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.shield,
              size: 14,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}
