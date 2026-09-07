import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  WalletRepositoryImpl(
    this.remoteDataSource,
    this.networkInfo,
  );

  @override
  Future<Either<Failure, Wallet>> getWallet() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final wallet = await remoteDataSource.getWallet();
      return Right(wallet);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WalletTransaction>>> getTransactions({
    int page = 1,
    int perPage = 15,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getTransactions(
        page: page,
        perPage: perPage,
        type: type,
        startDate: startDate?.toIso8601String().split('T')[0],
        endDate: endDate?.toIso8601String().split('T')[0],
      );
      return Right(response.transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> initiateTopUp({
    required double amount,
    required String gateway,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.initiateTopUp(
        amount: amount,
        gateway: gateway,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        if (statusCode == 401) {
          return UnauthorizedFailure(message.isNotEmpty ? message : 'Unauthorized');
        } else if (statusCode == 403) {
          return ServerFailure(message);
        } else if (statusCode == 400 || statusCode == 422) {
          return ValidationFailure(message);
        }
        return ServerFailure(message);
      case DioExceptionType.cancel:
        return const ServerFailure('Request cancelled');
      default:
        return const NetworkFailure('Network error');
    }
  }
}
