import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../../cart/data/datasources/cart_local_datasource.dart';
import '../../../cart/data/datasources/cart_remote_datasource.dart';
import '../../../cart/data/models/cart_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final CartLocalDataSource _cartLocalDataSource;
  final CartRemoteDataSource _cartRemoteDataSource;

  User? _cachedUser;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._storageService,
    this._cartLocalDataSource,
    this._cartRemoteDataSource,
  );

  @override
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Snapshot guest cart BEFORE we save the token, so _isGuest is still
      // true when we read local storage.
      final guestItems = await _cartLocalDataSource.getUnsyncedItems();

      final result = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save token and user
      await _storageService.setToken(result.token);
      await _storageService.setUser(UserModel(
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        phone: result.user.phone,
        avatar: result.user.avatar,
        emailVerifiedAt: result.user.emailVerifiedAt,
        createdAt: result.user.createdAt,
      ).toJson());

      // Migrate guest cart items to the server, then clear local cache so
      // the next getCart() fetches the merged server cart.
      await _migrateGuestCart(guestItems);

      _cachedUser = result.user;

      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? referralCode,
  }) async {
    try {
      // Snapshot guest cart BEFORE saving the token.
      final guestItems = await _cartLocalDataSource.getUnsyncedItems();

      final result = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        referralCode: referralCode,
      );

      // Save token and user
      await _storageService.setToken(result.token);
      await _storageService.setUser(UserModel(
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        phone: result.user.phone,
        avatar: result.user.avatar,
        emailVerifiedAt: result.user.emailVerifiedAt,
        createdAt: result.user.createdAt,
      ).toJson());

      // Migrate guest cart items to the server.
      await _migrateGuestCart(guestItems);

      _cachedUser = result.user;

      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Registration failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getUser() async {
    // Return cached user if available
    if (_cachedUser != null) {
      return Right(_cachedUser!);
    }

    // Try to get from local storage
    final userData = _storageService.getUser();
    if (userData != null) {
      _cachedUser = UserModel.fromJson(userData);
      return Right(_cachedUser!);
    }

    // Fetch from server
    try {
      final user = await _remoteDataSource.getUser();
      _cachedUser = user;
      await _storageService.setUser(user.toJson());
      return Right(user);
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        await _storageService.clearAuth();
        return const Left(UnauthorizedFailure('Session expired'));
      }
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Failed to get user: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      final user = await _remoteDataSource.updateProfile(
        name: name,
        phone: phone,
        avatarPath: avatarPath,
      );
      
      // Update cached user and storage
      _cachedUser = user;
      await _storageService.setUser(user.toJson());
      
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Failed to update profile: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (e) {
      // Continue with local logout even if server fails
    }

    await _storageService.clearAuth();
    _cachedUser = null;

    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> logoutAll() async {
    try {
      await _remoteDataSource.logoutAll();
    } catch (e) {
      // Continue with local logout
    }

    await _storageService.clearAuth();
    _cachedUser = null;

    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAuthConfig() async {
    try {
      final config = await _remoteDataSource.getAuthConfig();
      return Right(config);
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Failed to load config: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendPhoneOtp(String phone) async {
    try {
      final result = await _remoteDataSource.sendPhoneOtp(phone);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Failed to send OTP: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> verifyPhoneOtp(String phone, String code, {String? name, String? referralCode}) async {
    try {
      final result = await _remoteDataSource.verifyPhoneOtp(phone, code, name: name, referralCode: referralCode);
      return _handleAuthResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Verification failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendEmailOtp(String email) async {
    try {
      final result = await _remoteDataSource.sendEmailOtp(email);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Failed to send OTP: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> verifyEmailOtp(
    String email,
    String code, {
    String? name,
    String? phone,
    String? password,
    String? referralCode,
  }) async {
    try {
      final result = await _remoteDataSource.verifyEmailOtp(
        email,
        code,
        name: name,
        phone: phone,
        password: password,
        referralCode: referralCode,
      );
      return _handleAuthResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Verification failed: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> verifyFirebaseToken(String token, {String? phone, String? name, String? referralCode}) async {
    try {
      final result = await _remoteDataSource.verifyFirebaseToken(token, phone: phone, name: name, referralCode: referralCode);
      return _handleAuthResult(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Verification failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      
      // Clear local auth like logout
      await _storageService.clearAuth();
      _cachedUser = null;
      
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure('Failed to delete account: $e'));
    }
  }

  Future<Either<Failure, AuthResult>> _handleAuthResult(AuthResultModel result) async {
    // Snapshot guest cart BEFORE saving the token.
    final guestItems = await _cartLocalDataSource.getUnsyncedItems();

    // Save token and user
    await _storageService.setToken(result.token);
    await _storageService.setUser(UserModel(
      id: result.user.id,
      name: result.user.name,
      email: result.user.email,
      phone: result.user.phone,
      avatar: result.user.avatar,
      emailVerifiedAt: result.user.emailVerifiedAt,
      createdAt: result.user.createdAt,
    ).toJson());

    // Migrate guest cart items to the server.
    await _migrateGuestCart(guestItems);

    _cachedUser = result.user;

    return Right(result.toEntity());
  }

  /// Pushes locally-stored guest cart items to the server in a single batch
  /// request, then clears the local cache so the next [getCart] call fetches
  /// the merged server cart.
  ///
  /// Uses POST /cart/sync (batch endpoint) instead of N sequential
  /// POST /cart/items calls — eliminates partial-sync failures.
  /// Errors are swallowed — a failed migration is not fatal to the auth flow.
  Future<void> _migrateGuestCart(List<CartItemModel> guestItems) async {
    try {
      if (guestItems.isNotEmpty) {
        // Single round-trip batch sync
        await _cartRemoteDataSource.batchSyncItems(guestItems);
      }
    } catch (_) {
      // Migration failure is non-fatal; the user's server cart is still intact.
    } finally {
      // Always clear local cache so the next LoadCart fetches fresh from server.
      await _cartLocalDataSource.clearCart();
    }
  }

  @override
  bool get isLoggedIn => _storageService.isLoggedIn;

  @override
  User? get currentUser {
    if (_cachedUser != null) return _cachedUser;

    final userData = _storageService.getUser();
    if (userData != null) {
      _cachedUser = UserModel.fromJson(userData);
      return _cachedUser;
    }

    return null;
  }
}
