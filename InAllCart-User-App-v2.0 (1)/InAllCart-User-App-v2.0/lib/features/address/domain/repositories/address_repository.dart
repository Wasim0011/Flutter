import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address.dart';

abstract class AddressRepository {
  Future<Either<Failure, List<Address>>> getAddresses();
  Future<Either<Failure, Address>> getAddressById(int id);
  Future<Either<Failure, Address>> createAddress(Map<String, dynamic> data);
  Future<Either<Failure, Address>> updateAddress(int id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteAddress(int id);
  Future<Either<Failure, Address>> setDefaultAddress(int id);
}
