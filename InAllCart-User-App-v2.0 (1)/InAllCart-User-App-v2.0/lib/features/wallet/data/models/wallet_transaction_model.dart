import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.walletId,
    required super.type,
    required super.amount,
    required super.balanceBefore,
    required super.balanceAfter,
    required super.description,
    super.referenceType,
    super.referenceId,
    super.metadata,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as int,
      walletId: json['wallet_id'] as int,
      type: WalletTransactionType.fromString(json['type'] as String),
      amount: _parseDouble(json['amount']),
      balanceBefore: _parseDouble(json['balance_before']),
      balanceAfter: _parseDouble(json['balance_after']),
      description: json['description'] as String,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'wallet_id': walletId,
        'type': type.value,
        'amount': amount,
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
        'description': description,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'metadata': metadata,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
