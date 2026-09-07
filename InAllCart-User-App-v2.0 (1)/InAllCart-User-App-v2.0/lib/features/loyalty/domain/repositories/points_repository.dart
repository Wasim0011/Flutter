
import '../../data/models/points_model.dart';

abstract class PointsRepository {
  Future<PointsModel> getBalance();
  Future<List<PointTransactionModel>> getHistory();
  Future<void> redeemPoints(int points);
}
