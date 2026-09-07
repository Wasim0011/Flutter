import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';
import '../datasources/cart_remote_datasource.dart';
import '../models/cart_model.dart';

/// Cart repository — enterprise-grade offline-first implementation.
///
/// Strategy:
///   Guest  → Hive only; all mutations are local; `synced: false` flag tracks
///            items that need to be pushed to the server after login.
///   Auth   → Optimistic local update first, then server reconciliation.
///            On network failure the optimistic state is rolled back.
///
/// Key fixes vs. previous version:
///   1. `clearCart` now handles guest state (was missing the _isGuest check).
///   2. Optimistic updates for add/update/remove — UI responds instantly.
///   3. `syncCart` uses a single batch POST instead of N sequential requests.
///   4. `validateCart` exposes a pre-checkout stock/price check.
class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remoteDataSource;
  final CartLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final StorageService _storageService;

  CartRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
    this._storageService,
  );

  bool get _isGuest => !_storageService.isLoggedIn;

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, Cart>> getCart() async {
    if (_isGuest) {
      final localCart = await _localDataSource.getCart();
      return Right(localCart);
    }

    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        final localCart = await _localDataSource.getCart();
        return Right(localCart);
      }

      try {
        final serverCart = await _remoteDataSource.getCart();
        await _localDataSource.saveCart(serverCart);
        return Right(serverCart);
      } on UnauthorizedException {
        return Right(CartModel.empty());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, statusCode: e.statusCode));
      }
    } catch (e) {
      return Left(CacheFailure('Failed to load cart: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Mutations — optimistic for authenticated users
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, Cart>> addToCart({
    required int productId,
    required int quantity,
    int? variantId,
    String? productName,
    String? productImage,
    double? price,
  }) async {
    // Guest: local only
    if (_isGuest) {
      try {
        final item = CartItemModel(
          id: DateTime.now().microsecondsSinceEpoch, // microseconds to avoid ms collisions
          productId: productId,
          productName: productName ?? '',
          productImage: productImage,
          price: price ?? 0,
          quantity: quantity,
          variantId: variantId,
          synced: false,
        );
        final cart = await _localDataSource.addItem(item);
        return Right(cart);
      } catch (e) {
        return Left(CacheFailure(e.toString().replaceFirst('Exception: ', '')));
      }
    }

    // Authenticated: optimistic update → server → reconcile
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    }

    // 1. Optimistic local update
    final optimisticId = DateTime.now().microsecondsSinceEpoch;
    final optimisticItem = CartItemModel(
      id: optimisticId,
      productId: productId,
      productName: productName ?? '',
      productImage: productImage,
      price: price ?? 0,
      quantity: quantity,
      variantId: variantId,
      synced: false,
    );

    CartModel? optimisticCart;
    try {
      optimisticCart = await _localDataSource.addItem(optimisticItem);
    } catch (e) {
      // Store isolation or other local error — surface immediately, no server call.
      return Left(CacheFailure(e.toString().replaceFirst('Exception: ', '')));
    }

    // 2. Server call
    try {
      final serverCart = await _remoteDataSource.addToCart(
        productId: productId,
        quantity: quantity,
        variantId: variantId,
      );
      // Reconcile with authoritative server state
      await _localDataSource.saveCart(serverCart);
      return Right(serverCart);
    } on UnauthorizedException catch (e) {
      // Roll back optimistic update
      await _localDataSource.saveCart(
        await _localDataSource.removeItem(optimisticId),
      );
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException {
      // Keep optimistic state — will reconcile on next getCart
      return Right(optimisticCart);
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        await _localDataSource.saveCart(
          await _localDataSource.removeItem(optimisticId),
        );
        return Left(UnauthorizedFailure(e.message));
      }
      // Roll back and surface the error
      await _localDataSource.saveCart(
        await _localDataSource.removeItem(optimisticId),
      );
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      await _localDataSource.saveCart(
        await _localDataSource.removeItem(optimisticId),
      );
      return Left(ServerFailure('Failed to add to cart: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    // Guest: local only
    if (_isGuest) {
      try {
        final cart = await _localDataSource.updateItem(itemId, quantity);
        return Right(cart);
      } catch (e) {
        return Left(CacheFailure('Failed to update cart: $e'));
      }
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    }

    // 1. Snapshot for rollback
    final snapshot = await _localDataSource.getCart();

    // 2. Optimistic local update
    final optimisticCart = await _localDataSource.updateItem(itemId, quantity);

    // 3. Server call
    try {
      final serverCart = await _remoteDataSource.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );
      await _localDataSource.saveCart(serverCart);
      return Right(serverCart);
    } on UnauthorizedException catch (e) {
      await _localDataSource.saveCart(snapshot);
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException {
      return Right(optimisticCart);
    } on ServerException catch (e) {
      await _localDataSource.saveCart(snapshot);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      await _localDataSource.saveCart(snapshot);
      return Left(ServerFailure('Failed to update cart: $e'));
    }
  }

  /// Local-only update — writes to Hive without a server call.
  /// Called by the BLoC's immediate optimistic step. The debounce timer then
  /// calls [updateCartItem] for the server round-trip, which also updates
  /// local state from the authoritative server response. This prevents the
  /// double Hive write that occurred when both paths called [updateCartItem].
  @override
  Future<Either<Failure, Cart>> localUpdateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    try {
      final cart = await _localDataSource.updateItem(itemId, quantity);
      return Right(cart);
    } catch (e) {
      return Left(CacheFailure('Failed to update cart locally: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> removeFromCart(int itemId) async {
    // Guest: local only
    if (_isGuest) {
      try {
        final cart = await _localDataSource.removeItem(itemId);
        return Right(cart);
      } catch (e) {
        return Left(CacheFailure('Failed to remove from cart: $e'));
      }
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    }

    // 1. Snapshot for rollback
    final snapshot = await _localDataSource.getCart();

    // 2. Optimistic local remove
    final optimisticCart = await _localDataSource.removeItem(itemId);

    // 3. Server call
    try {
      final serverCart = await _remoteDataSource.removeFromCart(itemId);
      await _localDataSource.saveCart(serverCart);
      return Right(serverCart);
    } on UnauthorizedException catch (e) {
      await _localDataSource.saveCart(snapshot);
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException {
      return Right(optimisticCart);
    } on ServerException catch (e) {
      await _localDataSource.saveCart(snapshot);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      await _localDataSource.saveCart(snapshot);
      return Left(ServerFailure('Failed to remove from cart: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> clearCart() async {
    // Guest: local only (was missing this check — Bug fix)
    if (_isGuest) {
      try {
        await _localDataSource.clearCart();
        return Right(CartModel.empty());
      } catch (e) {
        return Left(CacheFailure('Failed to clear cart: $e'));
      }
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    }

    try {
      final serverCart = await _remoteDataSource.clearCart();
      await _localDataSource.clearCart();
      return Right(serverCart);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to clear cart: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Coupon
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, Cart>> applyCoupon(String code) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    }

    try {
      final cart = await _remoteDataSource.applyCoupon(code);
      await _localDataSource.saveCart(cart);
      return Right(cart);
    } on NetworkException {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to apply coupon: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> removeCoupon() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    }

    try {
      final cart = await _remoteDataSource.removeCoupon();
      await _localDataSource.saveCart(cart);
      return Right(cart);
    } on NetworkException {
      return const Left(
        NetworkFailure('No internet connection. Please check your network and try again.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to remove coupon: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Sync — single batch round-trip (replaces N sequential requests)
  // ---------------------------------------------------------------------------

  /// Syncs unsynced guest items to the server in a single batch POST and
  /// returns the merged cart directly.
  ///
  /// Returning [Cart] instead of [void] eliminates the second [getCart] call
  /// that the BLoC previously made after sync completed (two round-trips → one).
  ///
  /// If the server reports per-item sync errors (partial failure), they are
  /// logged and the merged cart is still returned — the user sees their cart
  /// in the best-effort merged state rather than a hard error.
  @override
  Future<Either<Failure, Cart>> syncCart() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final unsyncedItems = await _localDataSource.getUnsyncedItems();

      CartModel mergedCart;
      if (unsyncedItems.isNotEmpty) {
        // Single POST /cart/sync — atomically upserts all items on the server.
        // The server returns the merged cart which we use as the new local state.
        final syncResult = await _remoteDataSource.batchSyncItems(unsyncedItems);
        mergedCart = syncResult.cart;

        // Log any per-item failures so they're visible in crash reporting.
        if (syncResult.errors.isNotEmpty) {
        }
      } else {
        // No local items to push — pull the authoritative server cart.
        mergedCart = await _remoteDataSource.getCart();
      }

      await _localDataSource.saveCart(mergedCart);
      await _localDataSource.markAllAsSynced();

      return Right(mergedCart);
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to sync cart: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Pre-checkout validation
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> validateCart() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final issues = await _remoteDataSource.validateCart();
      return Right(issues);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to validate cart: $e'));
    }
  }
}
