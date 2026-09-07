import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/wallet_repository.dart';

class InitiateWalletTopUp {
  final WalletRepository repository;

  InitiateWalletTopUp(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required double amount,
    required String gateway,
  }) {
    return repository.initiateTopUp(
      amount: amount,
      gateway: gateway,
    );
  }
}
