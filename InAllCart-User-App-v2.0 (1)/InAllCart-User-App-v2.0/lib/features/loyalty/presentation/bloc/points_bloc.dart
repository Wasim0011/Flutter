
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/points_repository.dart';
import 'points_event.dart';
import 'points_state.dart';

class PointsBloc extends Bloc<PointsEvent, PointsState> {
  final PointsRepository repository;

  PointsBloc(this.repository) : super(PointsInitial()) {
    on<LoadPoints>(_onLoadPoints);
    on<RedeemPoints>(_onRedeemPoints);
  }

  Future<void> _onLoadPoints(LoadPoints event, Emitter<PointsState> emit) async {
    emit(PointsLoading());
    try {
      final points = await repository.getBalance();
      final transactions = await repository.getHistory();
      emit(PointsLoaded(points: points, transactions: transactions));
    } catch (e) {
      emit(PointsError(e.toString()));
    }
  }

  Future<void> _onRedeemPoints(RedeemPoints event, Emitter<PointsState> emit) async {
    final currentState = state;
    emit(PointsLoading());
    try {
      await repository.redeemPoints(event.points);
      emit(PointsRedemptionSuccess(event.points));
      add(const LoadPoints()); // Refresh data
    } catch (e) {
      emit(PointsError(e.toString()));
      // After showing the error, revert back to the previous loaded state
      // so the user can see their balance and try again
      if (currentState is PointsLoaded) {
        emit(currentState);
      }
    }
  }
}
