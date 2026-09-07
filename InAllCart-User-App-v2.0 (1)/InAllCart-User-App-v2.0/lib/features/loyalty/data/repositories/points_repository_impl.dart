
import '../../data/datasources/points_remote_datasource.dart';
import '../../data/models/points_model.dart';
import '../../domain/repositories/points_repository.dart';

class PointsRepositoryImpl implements PointsRepository {
  final PointsRemoteDataSource remoteDataSource;

  PointsRepositoryImpl(this.remoteDataSource);

  @override
  Future<PointsModel> getBalance() async {
    return await remoteDataSource.getBalance();
  }

  @override
  Future<List<PointTransactionModel>> getHistory() async {
    return await remoteDataSource.getHistory();
  }

  @override
  Future<void> redeemPoints(int points) async {
    await remoteDataSource.redeemPoints(points);
  }
}
