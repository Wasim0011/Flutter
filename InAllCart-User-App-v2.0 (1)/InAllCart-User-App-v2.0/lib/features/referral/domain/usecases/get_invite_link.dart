import '../repositories/referral_repository.dart';

class GetInviteLink {
  final ReferralRepository repository;

  GetInviteLink(this.repository);

  Future<String> call() async {
    return await repository.getInviteLink();
  }
}
