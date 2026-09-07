import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/wishlist_repository.dart';

// Events
abstract class WishlistEvent extends Equatable {
  const WishlistEvent();
  @override
  List<Object?> get props => [];
}

class LoadWishlist extends WishlistEvent {}

class ToggleWishlistProduct extends WishlistEvent {
  final int productId;
  const ToggleWishlistProduct(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ClearWishlist extends WishlistEvent {}

// States
abstract class WishlistState extends Equatable {
  final List<int> productIds;
  const WishlistState(this.productIds);
  @override
  List<Object?> get props => [productIds];
}

class WishlistInitial extends WishlistState {
  const WishlistInitial() : super(const []);
}

class WishlistLoading extends WishlistState {
  const WishlistLoading(super.productIds);
}

class WishlistLoaded extends WishlistState {
  const WishlistLoaded(super.productIds);
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(super.productIds, this.message);
  @override
  List<Object?> get props => [productIds, message];
}

// BLoC
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final WishlistRepository repository;

  WishlistBloc(this.repository) : super(const WishlistInitial()) {
    on<LoadWishlist>(_onLoadWishlist);
    on<ToggleWishlistProduct>(_onToggleWishlistProduct);
    on<ClearWishlist>(_onClearWishlist);
  }

  Future<void> _onLoadWishlist(LoadWishlist event, Emitter<WishlistState> emit) async {
    emit(WishlistLoading(state.productIds));
    try {
      final ids = await repository.getWishlistProductIds();
      emit(WishlistLoaded(ids));
    } catch (e) {
      emit(WishlistError(state.productIds, 'Failed to load wishlist'));
    }
  }

  Future<void> _onToggleWishlistProduct(ToggleWishlistProduct event, Emitter<WishlistState> emit) async {
    final currentIds = List<int>.from(state.productIds);
    final isPresent = currentIds.contains(event.productId);
    
    // Optimistically update the list
    if (isPresent) {
      currentIds.remove(event.productId);
    } else {
      currentIds.add(event.productId);
    }
    
    // Emit the optimistic state immediately for instant UI response
    emit(WishlistLoaded(currentIds));

    try {
      await repository.toggleWishlistProduct(event.productId);
      
      // We don't necessarily need to fetch all IDs again if we trust our local logic,
      // but let's do a quick check to ensure we're in sync.
      // This happens in the background now since we already emitted the new state.
      // final ids = await repository.getWishlistProductIds();
      // emit(WishlistLoaded(ids));
    } catch (e) {
      // Revert to the state before the failed operation
      final revertedIds = List<int>.from(state.productIds);
      if (isPresent) {
        revertedIds.add(event.productId);
      } else {
        revertedIds.remove(event.productId);
      }
      emit(WishlistError(revertedIds, 'Failed to update wishlist'));
    }
  }

  Future<void> _onClearWishlist(ClearWishlist event, Emitter<WishlistState> emit) async {
    try {
      await repository.clearWishlist();
      emit(const WishlistLoaded([]));
    } catch (e) {
      emit(WishlistError(state.productIds, 'Failed to clear wishlist'));
    }
  }
}
