import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetWalletBalance {
  final WalletRepository repository;

  GetWalletBalance(this.repository);

  Future<Either<Failure, Wallet>> call() {
    return repository.getWallet();
  }
}
