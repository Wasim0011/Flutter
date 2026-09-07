import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_datasource.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;

  AddressRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Address>>> getAddresses() async {
    try {
      final addresses = await remoteDataSource.getAddresses();
      return Right(addresses);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(UnauthorizedFailure('Please login to view addresses'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to load addresses'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Address>> getAddressById(int id) async {
    try {
      final address = await remoteDataSource.getAddressById(id);
      return Right(address);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(ServerFailure('Address not found'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to load address'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Address>> createAddress(
    Map<String, dynamic> data,
  ) async {
    try {
      final address = await remoteDataSource.createAddress(data);
      return Right(address);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(UnauthorizedFailure('Please login to add address'));
      }
      if (e.response?.statusCode == 422) {
        final message = e.response?.data['message'] ?? 'Invalid address data';
        return Left(ServerFailure(message));
      }
      return Left(ServerFailure(e.message ?? 'Failed to create address'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Address>> updateAddress(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final address = await remoteDataSource.updateAddress(id, data);
      return Right(address);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(ServerFailure('Address not found'));
      }
      if (e.response?.statusCode == 422) {
        final message = e.response?.data['message'] ?? 'Invalid address data';
        return Left(ServerFailure(message));
      }
      return Left(ServerFailure(e.message ?? 'Failed to update address'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAddress(int id) async {
    try {
      await remoteDataSource.deleteAddress(id);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(ServerFailure('Address not found'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to delete address'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Address>> setDefaultAddress(int id) async {
    try {
      final address = await remoteDataSource.setDefaultAddress(id);
      return Right(address);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(ServerFailure('Address not found'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to set default address'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
