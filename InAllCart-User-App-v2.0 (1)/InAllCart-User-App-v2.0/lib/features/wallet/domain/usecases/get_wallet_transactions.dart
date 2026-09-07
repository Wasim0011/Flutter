import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/wallet_transaction.dart';
import '../repositories/wallet_repository.dart';

class GetWalletTransactions {
  final WalletRepository repository;

  GetWalletTransactions(this.repository);

  Future<Either<Failure, List<WalletTransaction>>> call({
    int page = 1,
    int perPage = 15,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return repository.getTransactions(
      page: page,
      perPage: perPage,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
