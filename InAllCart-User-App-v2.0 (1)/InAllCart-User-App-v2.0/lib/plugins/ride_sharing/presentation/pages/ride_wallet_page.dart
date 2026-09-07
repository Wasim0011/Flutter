import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/widgets/unauthenticated_widget.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../../../features/wallet/presentation/bloc/wallet_event.dart';
import '../../../../features/wallet/presentation/bloc/wallet_state.dart';
import '../../../../features/wallet/domain/entities/wallet_transaction.dart';
import '../theme/ride_colors.dart';

/// Dedicated wallet screen for the ride-sharing experience, themed in the
/// plugin's black + yellow palette (independent of the host app's wallet UI).
class RideWalletPage extends StatefulWidget {
  const RideWalletPage({super.key});

  @override
  State<RideWalletPage> createState() => _RideWalletPageState();
}

class _RideWalletPageState extends State<RideWalletPage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(const LoadWallet());
  }

  String _formatAmount(double amount) {
    final configState = context.read<AppConfigBloc>().state;
    if (configState is AppConfigLoaded) {
      return configState.config.currencyConfig.formatAmount(amount);
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: const Text('My Wallet',
            style: TextStyle(
                color: RideColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 20)),
      ),
      body: authState is Unauthenticated
          ? Center(
              child: UnauthenticatedWidget(
                onLoginSuccess: () {
                  context.read<WalletBloc>().add(const LoadWallet());
                },
              ),
            )
          : BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is WalletLoading || state is WalletInitial) {
            return const Center(
                child: CircularProgressIndicator(color: RideColors.primary));
          }
          if (state is WalletError) {
            if (state.message.toLowerCase().contains('unauthenticated') ||
                state.message.contains('401')) {
              return Center(
                child: UnauthenticatedWidget(
                  onLoginSuccess: () {
                    context.read<WalletBloc>().add(const LoadWallet());
                  },
                ),
              );
            }
            return _errorState(state.message);
          }
          if (state is WalletLoaded) {
            return RefreshIndicator(
              color: RideColors.primary,
              onRefresh: () async {
                context.read<WalletBloc>().add(const RefreshWallet());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _balanceCard(state),
                  const SizedBox(height: 20),
                  _sectionTitle('Recent Transactions'),
                  const SizedBox(height: 8),
                  _transactions(state),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _balanceCard(WalletLoaded state) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: RideColors.darkGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: RideColors.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: RideColors.accent, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatAmount(state.wallet.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/wallet/top-up'),
              icon: const Icon(Icons.add_rounded,
                  size: 20, color: RideColors.onAccent),
              label: const Text(
                'Add Money',
                style: TextStyle(
                  color: RideColors.onAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RideColors.accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: RideColors.primary,
        ),
      );

  Widget _transactions(WalletLoaded state) {
    final txns = state.transactions.take(15).toList();
    if (txns.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No transactions yet',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }
    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: txns.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 64, color: Color(0xFFF2F2F2)),
        itemBuilder: (context, i) => _txnRow(txns[i]),
      ),
    );
  }

  Widget _txnRow(WalletTransaction t) {
    final credit = t.type.isCredit;
    final color = credit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.type.label,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(t.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${credit ? '+' : '-'} ${_formatAmount(t.amount)}',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  context.read<WalletBloc>().add(const LoadWallet()),
              style: ElevatedButton.styleFrom(
                backgroundColor: RideColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
