import 'package:equatable/equatable.dart';

class ReferralStats extends Equatable {
  final int totalReferrals;
  final int successfulReferrals;
  final double totalEarned;
  final String referralCode;
  final int freeDeliveriesRemaining;
  final String inviteText;

  const ReferralStats({
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.totalEarned,
    required this.referralCode,
    required this.freeDeliveriesRemaining,
    required this.inviteText,
  });

  @override
  List<Object?> get props => [
        totalReferrals,
        successfulReferrals,
        totalEarned,
        referralCode,
        freeDeliveriesRemaining,
        inviteText,
      ];
}
