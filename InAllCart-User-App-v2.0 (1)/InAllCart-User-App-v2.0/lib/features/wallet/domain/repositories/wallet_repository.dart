import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/wallet.dart';
import '../entities/wallet_transaction.dart';

/// Wallet Repository - Customer App
/// 
/// Per RBI guidelines, customer app does NOT support withdrawals
/// Customers can only:
/// - Add money to wallet (top-up)
/// - Use wallet money for orders
/// - View balance and transaction history
/// - Receive refunds in wallet
abstract class WalletRepository {
  /// Get current user's wallet balance and info
  Future<Either<Failure, Wallet>> getWallet();
  
  /// Get wallet transaction history with filters
  Future<Either<Failure, List<WalletTransaction>>> getTransactions({
    int page = 1,
    int perPage = 15,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Initiate wallet top-up via payment gateway
  Future<Either<Failure, Map<String, dynamic>>> initiateTopUp({
    required double amount,
    required String gateway,
  });
}
