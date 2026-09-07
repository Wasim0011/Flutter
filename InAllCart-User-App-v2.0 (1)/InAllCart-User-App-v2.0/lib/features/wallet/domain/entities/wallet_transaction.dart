import 'package:equatable/equatable.dart';

enum WalletTransactionType {
  credit('credit', 'Credit'),
  debit('debit', 'Debit'),
  orderPayment('order_payment', 'Order Payment'),
  topUp('top_up', 'Top-Up'),
  signupBonus('signup_bonus', 'Signup Bonus'),
  adminCredit('admin_credit', 'Admin Credit'),
  adminDebit('admin_debit', 'Admin Debit'),
  refund('refund', 'Refund'),
  withdrawal('withdrawal', 'Withdrawal'),
  withdrawalReversal('withdrawal_reversal', 'Withdrawal Reversal');

  final String value;
  final String label;

  const WalletTransactionType(this.value, this.label);

  static WalletTransactionType fromString(String value) {
    return WalletTransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WalletTransactionType.credit,
    );
  }

  bool get isCredit =>
      this == WalletTransactionType.credit ||
      this == WalletTransactionType.topUp ||
      this == WalletTransactionType.signupBonus ||
      this == WalletTransactionType.adminCredit ||
      this == WalletTransactionType.refund ||
      this == WalletTransactionType.withdrawalReversal;

  bool get isDebit =>
      this == WalletTransactionType.debit ||
      this == WalletTransactionType.orderPayment ||
      this == WalletTransactionType.adminDebit ||
      this == WalletTransactionType.withdrawal;
}

class WalletTransaction extends Equatable {
  final int id;
  final int walletId;
  final WalletTransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final String? referenceType;
  final int? referenceId;
  final Map<String, dynamic>? metadata;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.referenceType,
    this.referenceId,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        walletId,
        type,
        amount,
        balanceBefore,
        balanceAfter,
        description,
        referenceType,
        referenceId,
        metadata,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
