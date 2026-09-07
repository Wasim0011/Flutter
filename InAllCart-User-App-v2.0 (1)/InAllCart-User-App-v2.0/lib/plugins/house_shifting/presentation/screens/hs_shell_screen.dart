import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../../../features/wallet/presentation/bloc/wallet_event.dart';
import 'house_shifting_home_screen.dart';
import 'hs_orders_screen.dart';
import 'hs_payments_screen.dart';
import 'hs_account_screen.dart';

class HsShellScreen extends StatefulWidget {
  const HsShellScreen({super.key});

  @override
  State<HsShellScreen> createState() => _HsShellScreenState();
}

class _HsShellScreenState extends State<HsShellScreen> {
  int _currentIndex = 0;

  // Keep pages alive by using IndexedStack
  static const _tabs = [
    HouseShiftingHomeScreen(),
    HsOrdersScreen(),
    HsPaymentsScreen(),
    HsAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<WalletBloc>()..add(const LoadWallet()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _HsBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────
class _HsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HsBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                label: 'Home',
                icon: 'assets/icons/hs_home.svg',
                activeIcon: 'assets/icons/hs_home_filled.svg',
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                label: 'Orders',
                icon: 'assets/icons/hs_orders.svg',
                activeIcon: 'assets/icons/hs_orders_filled.svg',
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                label: 'Payments',
                icon: 'assets/icons/hs_wallet.svg',
                activeIcon: 'assets/icons/hs_wallet_filled.svg',
                onTap: onTap,
              ),
              _NavItem(
                index: 3,
                currentIndex: currentIndex,
                label: 'Account',
                icon: 'assets/icons/hs_account.svg',
                activeIcon: 'assets/icons/hs_account_filled.svg',
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String label;
  final String icon;
  final String activeIcon;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? AppColors.primary : AppColors.textTertiary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: SvgPicture.asset(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
