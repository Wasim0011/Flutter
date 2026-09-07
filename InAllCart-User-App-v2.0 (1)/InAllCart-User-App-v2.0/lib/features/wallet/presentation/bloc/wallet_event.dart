import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadWallet extends WalletEvent {
  const LoadWallet();
}

class RefreshWallet extends WalletEvent {
  const RefreshWallet();
}

class LoadTransactions extends WalletEvent {
  final int page;
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool refresh;

  const LoadTransactions({
    this.page = 1,
    this.type,
    this.startDate,
    this.endDate,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, type, startDate, endDate, refresh];
}

class InitiateTopUp extends WalletEvent {
  final double amount;
  final String paymentGateway;

  const InitiateTopUp({
    required this.amount,
    required this.paymentGateway,
  });

  @override
  List<Object?> get props => [amount, paymentGateway];
}
