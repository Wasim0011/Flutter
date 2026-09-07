import '../repositories/referral_repository.dart';
import '../entities/referral_stats.dart';

class GetReferralStats {
  final ReferralRepository repository;

  GetReferralStats(this.repository);

  Future<ReferralStats> call() async {
    return await repository.getReferralStats();
  }
}
