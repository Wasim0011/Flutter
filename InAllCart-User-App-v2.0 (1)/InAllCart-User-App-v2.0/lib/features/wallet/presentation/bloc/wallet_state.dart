import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final Wallet wallet;
  final List<WalletTransaction> transactions;
  final bool hasMoreTransactions;
  final int currentPage;
  final bool isLoadingMore;

  const WalletLoaded({
    required this.wallet,
    this.transactions = const [],
    this.hasMoreTransactions = false,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  WalletLoaded copyWith({
    Wallet? wallet,
    List<WalletTransaction>? transactions,
    bool? hasMoreTransactions,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return WalletLoaded(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      hasMoreTransactions: hasMoreTransactions ?? this.hasMoreTransactions,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        wallet,
        transactions,
        hasMoreTransactions,
        currentPage,
        isLoadingMore,
      ];
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}

class TopUpInitiated extends WalletState {
  final String paymentUrl;
  final String transactionId;
  final Map<String, dynamic>? gatewayData;

  const TopUpInitiated({
    required this.paymentUrl,
    required this.transactionId,
    this.gatewayData,
  });

  @override
  List<Object?> get props => [paymentUrl, transactionId, gatewayData];
}
