import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories.dart';

// ============== EVENTS ==============

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {
  final bool forceRefresh;
  const LoadCategories({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadFeaturedCategories extends CategoryEvent {
  final int limit;
  final bool forceRefresh;
  const LoadFeaturedCategories({this.limit = 8, this.forceRefresh = false});

  @override
  List<Object?> get props => [limit, forceRefresh];
}

/// Internal event triggered by stream updates
class _StreamDataUpdated extends CategoryEvent {
  final List<Category> categories;
  final bool isStale;
  const _StreamDataUpdated(this.categories, {this.isStale = false});

  @override
  List<Object?> get props => [categories, isStale];
}

// ============== STATES ==============

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoriesLoaded extends CategoryState {
  final List<Category> categories;
  final DateTime loadedAt;
  final bool isStale;

  CategoriesLoaded(this.categories, {this.isStale = false}) 
      : loadedAt = DateTime.now();

  @override
  List<Object?> get props => [categories, loadedAt, isStale];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============== CATEGORY BLOC ==============

/// MNC-level CategoryBloc with reactive stream subscription
/// 
/// Architecture:
/// - Subscribes to DataSyncService streams for real-time updates
/// - Automatic UI updates when background refresh completes
/// - Proper cleanup on dispose
/// - Stale data indication for UX
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategories _getCategories;
  final GetFeaturedCategories _getFeaturedCategories;
  final DataSyncService _dataSyncService;
  
  /// Stream subscription for automatic updates
  StreamSubscription<DataState<List<Category>>>? _streamSubscription;
  
  /// Track if we're loading featured or all categories
  bool _loadingFeatured = false;
  
  /// Track last emitted data hash to avoid duplicate emissions
  String? _lastDataHash;

  CategoryBloc(this._getCategories, this._getFeaturedCategories)
      : _dataSyncService = DataSyncService(),
        super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<LoadFeaturedCategories>(_onLoadFeaturedCategories);
    on<_StreamDataUpdated>(_onStreamDataUpdated);
    
    _subscribeToFeaturedCategoriesStream();
  }

  /// Generate hash for data comparison (detects any change including names, images, etc.)
  String _generateDataHash(List<Category> categories) {
    final buffer = StringBuffer();
    for (final cat in categories) {
      buffer.write('${cat.id}_${cat.name}_${cat.imageUrl}_${cat.flags.isFeatured}_');
    }
    return buffer.toString().hashCode.toString();
  }

  /// Subscribe to featured categories stream
  void _subscribeToFeaturedCategoriesStream() {
    _streamSubscription?.cancel();
    
    _streamSubscription = _dataSyncService.featuredCategoriesStream
        .distinct((prev, curr) {
          if (!prev.hasData || !curr.hasData) return false;
          return _generateDataHash(prev.data!) == _generateDataHash(curr.data!) &&
                 prev.isStale == curr.isStale;
        })
        .listen(
      (dataState) {
        if (dataState.hasData && !isClosed && _loadingFeatured) {
          final newHash = _generateDataHash(dataState.data!);
          
          if (_lastDataHash != newHash || 
              (state is CategoriesLoaded && (state as CategoriesLoaded).isStale != dataState.isStale)) {
            _lastDataHash = newHash;
            add(_StreamDataUpdated(dataState.data!, isStale: dataState.isStale));
          }
        }
      },
    );
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoryState> emit) async {
    _loadingFeatured = false;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    
    emit(CategoryLoading());
    
    final result = await _getCategories(forceRefresh: event.forceRefresh);
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }

  Future<void> _onLoadFeaturedCategories(LoadFeaturedCategories event, Emitter<CategoryState> emit) async {
    _loadingFeatured = true;
    
    if (state is! CategoriesLoaded) {
      emit(CategoryLoading());
    }
    
    final result = await _getFeaturedCategories(
      limit: event.limit, 
      forceRefresh: event.forceRefresh,
    );
    
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (categories) {
        _lastDataHash = _generateDataHash(categories);
        emit(CategoriesLoaded(categories));
      },
    );
  }

  /// Handle stream updates - this is called when background refresh completes
  void _onStreamDataUpdated(_StreamDataUpdated event, Emitter<CategoryState> emit) {
    if (_loadingFeatured) {
      emit(CategoriesLoaded(event.categories, isStale: event.isStale));
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
