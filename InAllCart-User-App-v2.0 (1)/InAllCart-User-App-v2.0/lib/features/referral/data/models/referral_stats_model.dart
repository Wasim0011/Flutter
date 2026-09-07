import '../../domain/entities/referral_stats.dart';

class ReferralStatsModel extends ReferralStats {
  const ReferralStatsModel({
    required super.totalReferrals,
    required super.successfulReferrals,
    required super.totalEarned,
    required super.referralCode,
    required super.freeDeliveriesRemaining,
    required super.inviteText,
  });

  factory ReferralStatsModel.fromJson(Map<String, dynamic> json) {
    return ReferralStatsModel(
      totalReferrals: (json['total_referrals'] as num?)?.toInt() ?? 0,
      successfulReferrals: (json['successful_referrals'] as num?)?.toInt() ?? 0,
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0.0,
      referralCode: json['referral_code'] ?? '',
      freeDeliveriesRemaining: (json['free_deliveries_remaining'] as num?)?.toInt() ?? 0,
      inviteText: json['invite_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_referrals': totalReferrals,
      'successful_referrals': successfulReferrals,
      'total_earned': totalEarned,
      'referral_code': referralCode,
      'free_deliveries_remaining': freeDeliveriesRemaining,
      'invite_text': inviteText,
    };
  }
}
