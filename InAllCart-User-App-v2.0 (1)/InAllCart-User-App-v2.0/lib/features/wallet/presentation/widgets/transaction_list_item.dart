import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../domain/entities/wallet_transaction.dart';

class TransactionListItem extends StatelessWidget {
  final WalletTransaction transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final currencyConfig = configState is AppConfigLoaded 
            ? configState.config.currencyConfig 
            : null;
        
        final formattedAmount = currencyConfig != null
            ? currencyConfig.formatAmount(transaction.amount)
            : transaction.amount.toStringAsFixed(0);
        
        final formattedBalance = currencyConfig != null
            ? currencyConfig.formatAmount(transaction.balanceAfter)
            : transaction.balanceAfter.toStringAsFixed(0);

        return Row(
          children: [
            // Transaction Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconBackgroundColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTransactionIcon(),
                color: _getIconBackgroundColor(),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTransactionLabel(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_isCredit() ? '+' : '-'} $formattedAmount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isCredit() ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance: $formattedBalance',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  bool _isCredit() {
    return transaction.type == WalletTransactionType.credit ||
        transaction.type == WalletTransactionType.topUp ||
        transaction.type == WalletTransactionType.refund ||
        transaction.type == WalletTransactionType.signupBonus ||
        transaction.type == WalletTransactionType.adminCredit ||
        transaction.type == WalletTransactionType.withdrawalReversal;
  }

  IconData _getTransactionIcon() {
    switch (transaction.type) {
      case WalletTransactionType.credit:
      case WalletTransactionType.adminCredit:
        return Icons.add_circle_outline;
      case WalletTransactionType.debit:
      case WalletTransactionType.adminDebit:
        return Icons.remove_circle_outline;
      case WalletTransactionType.topUp:
        return Icons.account_balance_wallet;
      case WalletTransactionType.orderPayment:
        return Icons.shopping_bag_outlined;
      case WalletTransactionType.refund:
        return Icons.refresh;
      case WalletTransactionType.withdrawal:
        return Icons.arrow_upward;
      case WalletTransactionType.withdrawalReversal:
        return Icons.undo;
      case WalletTransactionType.signupBonus:
        return Icons.card_giftcard;
    }
  }

  Color _getIconBackgroundColor() {
    if (_isCredit()) {
      return AppColors.success;
    } else {
      return AppColors.error;
    }
  }

  String _getTransactionLabel() {
    switch (transaction.type) {
      case WalletTransactionType.credit:
        return 'Money Added';
      case WalletTransactionType.debit:
        return 'Money Deducted';
      case WalletTransactionType.topUp:
        return 'Wallet Top-up';
      case WalletTransactionType.orderPayment:
        return 'Order Payment';
      case WalletTransactionType.refund:
        return 'Refund Received';
      case WalletTransactionType.withdrawal:
        return 'Withdrawal';
      case WalletTransactionType.withdrawalReversal:
        return 'Withdrawal Reversed';
      case WalletTransactionType.signupBonus:
        return 'Signup Bonus';
      case WalletTransactionType.adminCredit:
        return 'Admin Credit';
      case WalletTransactionType.adminDebit:
        return 'Admin Debit';
    }
  }
}
