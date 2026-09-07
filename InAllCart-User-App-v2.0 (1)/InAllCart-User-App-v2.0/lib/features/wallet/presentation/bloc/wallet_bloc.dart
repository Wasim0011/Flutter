import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/usecases/get_wallet_balance.dart';
import '../../domain/usecases/get_wallet_transactions.dart';
import '../../domain/usecases/initiate_wallet_top_up.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletBalance getWalletBalance;
  final GetWalletTransactions getWalletTransactions;
  final InitiateWalletTopUp initiateWalletTopUp;

  WalletBloc({
    required this.getWalletBalance,
    required this.getWalletTransactions,
    required this.initiateWalletTopUp,
  }) : super(const WalletInitial()) {
    on<LoadWallet>(_onLoadWallet);
    on<RefreshWallet>(_onRefreshWallet);
    on<LoadTransactions>(_onLoadTransactions);
    on<InitiateTopUp>(_onInitiateTopUp);
  }

  Future<void> _onLoadWallet(
    LoadWallet event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());

    final result = await getWalletBalance();

    result.fold(
      (failure) {
        emit(WalletError(failure.message));
      },
      (wallet) {
        emit(WalletLoaded(wallet: wallet));
        
        // Automatically load recent transactions
        add(const LoadTransactions(page: 1));
      },
    );
  }

  Future<void> _onRefreshWallet(
    RefreshWallet event,
    Emitter<WalletState> emit,
  ) async {
    
    final result = await getWalletBalance();

    result.fold(
      (failure) {
        // Keep current state on error
        if (state is WalletLoaded) {
          // Optionally show a snackbar or toast
        } else {
          emit(WalletError(failure.message));
        }
      },
      (wallet) {
        if (state is WalletLoaded) {
          final currentState = state as WalletLoaded;
          emit(currentState.copyWith(wallet: wallet));
        } else {
          emit(WalletLoaded(wallet: wallet));
        }
        
        // Refresh transactions as well
        add(const LoadTransactions(page: 1, refresh: true));
      },
    );
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<WalletState> emit,
  ) async {
    
    if (state is! WalletLoaded) {
      return;
    }

    final currentState = state as WalletLoaded;

    if (event.refresh) {
      // Don't show loading state for refresh, just update transactions
    } else if (event.page > 1) {
      emit(currentState.copyWith(isLoadingMore: true));
    }

    final result = await getWalletTransactions(
      page: event.page,
      perPage: 20,
      type: event.type,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) {
        if (event.page == 1) {
          emit(currentState.copyWith(
            transactions: [],
            hasMoreTransactions: false,
            isLoadingMore: false,
          ));
        } else {
          emit(currentState.copyWith(isLoadingMore: false));
        }
      },
      (transactions) {
        
        List<WalletTransaction> allTransactions;
        if (event.page == 1 || event.refresh) {
          allTransactions = transactions;
        } else {
          allTransactions = [...currentState.transactions, ...transactions];
        }

        emit(currentState.copyWith(
          transactions: allTransactions,
          hasMoreTransactions: transactions.length >= 20,
          currentPage: event.page,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> _onInitiateTopUp(
    InitiateTopUp event,
    Emitter<WalletState> emit,
  ) async {
    
    if (state is! WalletLoaded) {
      emit(const WalletError('Please load wallet first'));
      return;
    }

    final currentState = state as WalletLoaded;
    emit(const WalletLoading());

    final result = await initiateWalletTopUp(
      amount: event.amount,
      gateway: event.paymentGateway,
    );

    result.fold(
      (failure) {
        emit(WalletError(failure.message));
        // Restore previous state after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (!isClosed) {
            emit(currentState);
          }
        });
      },
      (topUpResponse) {
        emit(TopUpInitiated(
          paymentUrl: topUpResponse['payment_url'] as String? ?? '',
          transactionId: topUpResponse['transaction_id'] as String? ?? '',
          gatewayData: topUpResponse['gateway_data'] as Map<String, dynamic>?,
        ));
      },
    );
  }
}
