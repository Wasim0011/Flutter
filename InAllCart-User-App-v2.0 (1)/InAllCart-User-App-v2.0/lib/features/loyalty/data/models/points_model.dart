
class PointsModel {
  final int availablePoints;
  final int totalEarned;
  final int totalRedeemed;
  final double currencyValue;
  final int conversionRate;

  PointsModel({
    required this.availablePoints,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.currencyValue,
    required this.conversionRate,
  });

  factory PointsModel.fromJson(Map<String, dynamic> json) {
    return PointsModel(
      availablePoints: json['available_points'] as int? ?? 0,
      totalEarned: json['total_earned'] as int? ?? 0,
      totalRedeemed: json['total_redeemed'] as int? ?? 0,
      currencyValue: (json['currency_value'] as num?)?.toDouble() ?? 0.0,
      conversionRate: json['conversion_rate'] as int? ?? 100,
    );
  }
}

class PointTransactionModel {
  final int id;
  final String type;
  final int points;
  final int pointsBefore;
  final int pointsAfter;
  final String description;
  final String createdAt;
  final Map<String, dynamic>? metadata;

  PointTransactionModel({
    required this.id,
    required this.type,
    required this.points,
    required this.pointsBefore,
    required this.pointsAfter,
    required this.description,
    required this.createdAt,
    this.metadata,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String?) ?? 'earned',
      points: (json['points'] as num?)?.toInt() ?? 0,
      pointsBefore: (json['points_before'] as num?)?.toInt() ?? 0,
      pointsAfter: (json['points_after'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?) ?? '',
      createdAt: (json['created_at'] as String?) ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
