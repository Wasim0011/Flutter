import '../../domain/entities/referral_stats.dart';
import '../../domain/repositories/referral_repository.dart';
import '../datasources/referral_remote_datasource.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralRemoteDataSource remoteDataSource;

  ReferralRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ReferralStats> getReferralStats() async {
    return await remoteDataSource.getReferralStats();
  }

  @override
  Future<String> getInviteLink() async {
    return await remoteDataSource.getInviteLink();
  }
}
