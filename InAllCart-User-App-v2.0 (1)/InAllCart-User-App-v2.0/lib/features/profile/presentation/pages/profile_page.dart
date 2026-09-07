import 'package:flutter/material.dart';
import '../../../../core/widgets/cached_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../address/presentation/bloc/address_bloc.dart';
import '../../../static_pages/presentation/pages/general_info_page.dart';
import '../../../support/presentation/screens/support_tickets_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AddressBloc>()..add(LoadAddresses()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is! Authenticated) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final user = state.user;

            return CustomScrollView(
              slivers: [
                // Modern Header with Gradient
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -50,
                            top: -50,
                            child: CircleAvatar(
                              radius: 100,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 40,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CachedImage.avatar(
                                    imageUrl: user.avatar,
                                    radius: 40,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      user.phone ?? user.email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () => context.push(Routes.editProfile),
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // VIP Membership Banner
                        const _VipProfileBannerWidget(),

                        const SizedBox(height: 24),

                        // Quick Actions Grid
                        const _QuickActionsSection(),

                        const SizedBox(height: 24),

                        // Main Sections
                        _ProfileSection(
                          title: 'Account Settings',
                          items: [
                            _ProfileMenuItem(
                              icon: Icons.favorite_border_rounded,
                              iconColor: Colors.pink,
                              title: 'My Wishlist',
                              onTap: () => context.push(Routes.wishlist),
                            ),
                            BlocBuilder<AddressBloc, AddressState>(
                              builder: (context, addressState) {
                                final count = addressState.addresses.length;
                                return _ProfileMenuItem(
                                  icon: Icons.location_on_outlined,
                                  iconColor: Colors.blue,
                                  title: 'Manage Addresses',
                                  subtitle: count > 0 ? '$count saved locations' : 'Add delivery address',
                                  onTap: () => context.push(Routes.addresses),
                                );
                              },
                            ),
                            _ProfileMenuItem(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: Colors.teal,
                              title: 'My Wallet',
                              onTap: () => context.push(Routes.wallet),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _ProfileSection(
                          title: 'Rewards & Offers',
                          items: [
                            _ProfileMenuItem(
                              icon: Icons.card_giftcard_rounded,
                              iconColor: Colors.orange,
                              title: 'Cashback & Coupons',
                              onTap: () => context.push(Routes.cashback),
                            ),
                            _ProfileMenuItem(
                              svgIcon: 'assets/icons/refer_earn.svg',
                              iconColor: Colors.purple,
                              title: 'Refer & Earn',
                              subtitle: 'Get ₹50 for every friend you invite',
                              onTap: () => context.push(Routes.referral),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _ProfileSection(
                          title: 'Support & Info',
                          items: [
                            _ProfileMenuItem(
                              icon: Icons.notifications_none_rounded,
                              iconColor: Colors.amber,
                              title: 'Notification Preferences',
                              onTap: () => context.push(Routes.notifications),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.help_outline_rounded,
                              iconColor: Colors.cyan,
                              title: 'Help Center',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
                              ),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.info_outline_rounded,
                              iconColor: Colors.grey,
                              title: 'About App',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GeneralInfoPage()),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Logout and Danger Zone
                        _DangerZoneSection(
                          onLogout: () => context.read<AuthBloc>().add(LogoutEvent()),
                          onDelete: () => _showDeleteConfirmation(context),
                        ),

                        const SizedBox(height: 40),

                        // App Version Info
                        const _VersionInfo(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final configState = context.read<AppConfigBloc>().state;
    final gracePeriod = configState is AppConfigLoaded ? configState.config.accountDeletionGracePeriod : 7;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Delete Account?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete your account? This action will set your data for permanent removal after $gracePeriod days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.read<AuthBloc>().add(DeleteAccountEvent());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete'),
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
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length * 2 - 1, (index) {
              if (index.isOdd) {
                return Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100, indent: 56);
              }
              return items[index ~/ 2];
            }),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData? icon;
  final String? svgIcon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    this.icon,
    this.svgIcon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: svgIcon != null
            ? SvgPicture.asset(svgIcon!, width: 20, height: 20, colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn))
            : Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionItem(
          icon: Icons.local_shipping_outlined,
          label: 'Orders',
          color: Colors.blue,
          onTap: () => context.push(Routes.orders),
        ),
        const SizedBox(width: 12),
        _QuickActionItem(
          icon: Icons.headset_mic_outlined,
          label: 'Support',
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketsScreen())),
        ),
        const SizedBox(width: 12),
        _QuickActionItem(
          icon: Icons.payments_outlined,
          label: 'Payment',
          color: Colors.teal,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _QuickActionItem(
          icon: Icons.card_giftcard_rounded,
          label: 'Coupons',
          color: Colors.pink,
          onTap: () => context.push(Routes.cashback),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerZoneSection extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  const _DangerZoneSection({required this.onLogout, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onDelete,
          child: Text(
            'Delete Account',
            style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _VersionInfo extends StatelessWidget {
  const _VersionInfo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'InAllCart v2.0',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            'App version 26.1.3 • v120-9',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _VipProfileBannerWidget extends StatefulWidget {
  const _VipProfileBannerWidget();

  @override
  State<_VipProfileBannerWidget> createState() => _VipProfileBannerWidgetState();
}

class _VipProfileBannerWidgetState extends State<_VipProfileBannerWidget> {
  bool _isVip = false;
  String? _planName;
  int _remainingDays = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkVip();
  }

  Future<void> _checkVip() async {
    try {
      final apiClient = getIt<ApiClient>();
      final res = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.membershipStatus,
        parser: (data) => data as Map<String, dynamic>,
      );
      if (mounted) {
        setState(() {
          _isVip = res['is_vip'] == true;
          final m = res['membership'] as Map<String, dynamic>?;
          _planName = m?['plan_name'] as String? ?? 'VIP Member';
          _remainingDays = (m?['remaining_days'] as int?) ?? 0;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    if (_isVip) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C2D12), Color(0xFFC2410C), Color(0xFFEA580C)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _planName ?? 'VIP Membership',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '$_remainingDays days left',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push(Routes.vipMembership),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFC2410C),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to VIP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Free delivery & extra perks',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push(Routes.vipMembership),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }
}
