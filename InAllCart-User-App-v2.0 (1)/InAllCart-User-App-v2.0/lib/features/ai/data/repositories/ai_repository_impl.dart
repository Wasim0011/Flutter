import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../datasources/ai_local_datasource.dart';
import '../../domain/entities/ai_chat_message.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource remoteDataSource;
  final AiLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AiRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AiChatResponse>> sendMessage(String message, {List<Map<String, dynamic>>? history, String? image}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.sendMessage(message, history: history, image: image);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(const NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<AiChatMessage>>> getChatHistory() async {
    try {
      final history = await localDataSource.getChatHistory();
      return Right(history);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveMessage(AiChatMessage message) async {
    try {
      await localDataSource.saveMessage(message);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory() async {
    try {
      await localDataSource.clearHistory();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
