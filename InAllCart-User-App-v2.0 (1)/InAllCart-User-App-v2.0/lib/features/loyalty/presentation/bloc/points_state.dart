
import 'package:equatable/equatable.dart';
import '../../data/models/points_model.dart';

abstract class PointsState extends Equatable {
  const PointsState();

  @override
  List<Object> get props => [];
}

class PointsInitial extends PointsState {}

class PointsLoading extends PointsState {}

class PointsLoaded extends PointsState {
  final PointsModel points;
  final List<PointTransactionModel> transactions;

  const PointsLoaded({required this.points, required this.transactions});

  @override
  List<Object> get props => [points, transactions];
}

class PointsError extends PointsState {
  final String message;

  const PointsError(this.message);

  @override
  List<Object> get props => [message];
}

class PointsRedemptionSuccess extends PointsState {
  final int pointsRedeemed;

  const PointsRedemptionSuccess(this.pointsRedeemed);

  @override
  List<Object> get props => [pointsRedeemed];
}
