import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../../../core/di/injection.dart';
import '../theme/ride_colors.dart';
import 'ride_home_page.dart';
import 'ride_history_page.dart';
import 'ride_wallet_page.dart';
import 'ride_profile_page.dart';

/// Root shell for the ride-sharing rider experience with a sticky
/// black + yellow bottom navigation bar (Home / My Rides / Wallet / Profile),
/// matching the VYSA reference design.
///
/// The Home tab hosts the full-screen booking map; tabs are kept alive via
/// [IndexedStack] so an in-progress booking is never lost when switching tabs.
class RideShellPage extends StatefulWidget {
  const RideShellPage({super.key});

  @override
  State<RideShellPage> createState() => _RideShellPageState();
}

class _RideShellPageState extends State<RideShellPage> {
  int _currentIndex = 0;
  final RideHomeBackController _homeBackController = RideHomeBackController();

  late final List<Widget> _pages = [
    RideHomePage(backController: _homeBackController),
    const RideHistoryPage(),
    BlocProvider(
      create: (_) => getIt<WalletBloc>(),
      child: const RideWalletPage(),
    ),
    // Profile can ask the shell to switch tabs (My Rides / Wallet) so it
    // stays inside the ride experience instead of pushing host-app pages.
    RideProfilePage(onSelectTab: (i) => setState(() => _currentIndex = i)),
  ];

  Future<void> _onBack() async {
    // Not on Home → return to Home.
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    // On Home → let the ride flow step back first.
    if (_homeBackController.handleBack()) return;

    // Pop cleanly back to main app home page using GoRouter
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _RideBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

class _RideBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _RideBottomNav({required this.currentIndex, required this.onTap});

  static const _items = <_NavSpec>[
    _NavSpec(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavSpec(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'My Rides'),
    _NavSpec(Icons.account_balance_wallet_rounded,
        Icons.account_balance_wallet_outlined, 'Wallet'),
    _NavSpec(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final spec = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? RideColors.accent.withOpacity(0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? spec.activeIcon : spec.icon,
                          size: 23,
                          color: selected
                              ? RideColors.primary
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          spec.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected
                                ? RideColors.primary
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavSpec(this.activeIcon, this.icon, this.label);
}
