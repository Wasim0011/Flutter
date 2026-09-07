
import 'package:equatable/equatable.dart';

abstract class PointsEvent extends Equatable {
  const PointsEvent();

  @override
  List<Object> get props => [];
}

class LoadPoints extends PointsEvent {
  const LoadPoints();
}

class RedeemPoints extends PointsEvent {
  final int points;

  const RedeemPoints(this.points);

  @override
  List<Object> get props => [points];
}
