import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/ride_colors.dart';

/// Premium side navigation drawer for the ride-sharing experience.
///
/// When the ride-sharing plugin is active the app has no bottom navigation
/// bar (the rider lands straight on the full-screen map), so this drawer is
/// the single entry point to the rider's account.
class RideAppDrawer extends StatelessWidget {
  const RideAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFAFAFC),
      width: 308,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
              children: [
                _DrawerItem(
                  icon: Icons.arrow_back_rounded,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF2E7D32),
                  label: 'Back to Main App',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
                const SizedBox(height: 10),
                _sectionLabel('RIDES'),
                _DrawerItem(
                  icon: Icons.directions_car_rounded,
                  iconBg: RideColors.accentSoft,
                  iconColor: RideColors.primary,
                  label: 'Book a Ride',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/ride-sharing');
                  },
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_rounded,
                  iconBg: const Color(0xFFF3F4F6),
                  iconColor: RideColors.primary,
                  label: 'My Rides',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/ride-sharing/history');
                  },
                ),
                const SizedBox(height: 16),
                _sectionLabel('ACCOUNT'),
                _DrawerItem(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  label: 'Wallet',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(Routes.wallet);
                  },
                ),
                _DrawerItem(
                  icon: Icons.location_on_rounded,
                  iconBg: const Color(0xFFFEF3F2),
                  iconColor: const Color(0xFFEF4444),
                  label: 'Saved Places',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(Routes.addresses);
                  },
                ),
                _DrawerItem(
                  icon: Icons.notifications_rounded,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(Routes.notifications);
                  },
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  iconBg: const Color(0xFFF5F3FF),
                  iconColor: const Color(0xFF7C3AED),
                  label: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(Routes.settings);
                  },
                ),
              ],
            ),
          ),
          // ── Login / Logout pinned to bottom ──────────────────────
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isAuthenticated = state is Authenticated;
                  return _DrawerItem(
                    icon: isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
                    iconBg: isAuthenticated ? const Color(0xFFFEF2F2) : const Color(0xFFFFF8E1),
                    iconColor: isAuthenticated ? AppColors.error : RideColors.primary,
                    label: isAuthenticated ? 'Logout' : 'Login',
                    labelColor: isAuthenticated ? AppColors.error : RideColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      if (isAuthenticated) {
                        context.read<AuthBloc>().add(LogoutEvent());
                      } else {
                        context.push('/login');
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is Authenticated ? state.user : null;
        final name = user?.name ?? 'Guest';
        final subtitle = user?.phone ?? user?.email ?? '';
        final initial =
            name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'G';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
          decoration: const BoxDecoration(
            gradient: RideColors.darkGradient,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            (user?.avatar != null && user!.avatar!.isNotEmpty)
                                ? NetworkImage(user.avatar!)
                                : null,
                        child: (user?.avatar == null || user!.avatar!.isEmpty)
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: RideColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          SizedBox(width: 3),
                          Text(
                            'Rider',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
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
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: labelColor ?? const Color(0xFF1F2937),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: labelColor?.withOpacity(0.4) ??
                        const Color(0xFFD1D5DB)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
