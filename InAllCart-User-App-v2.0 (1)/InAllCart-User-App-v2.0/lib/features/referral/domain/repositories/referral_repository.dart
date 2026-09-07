import '../entities/referral_stats.dart';

abstract class ReferralRepository {
  Future<ReferralStats> getReferralStats();
  Future<String> getInviteLink();
}
