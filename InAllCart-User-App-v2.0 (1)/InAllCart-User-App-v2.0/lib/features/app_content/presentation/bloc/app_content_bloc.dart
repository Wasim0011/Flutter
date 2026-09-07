import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/app_content.dart';
import '../../domain/usecases/get_app_content.dart';
import '../../domain/usecases/get_category_screen_content.dart';

// Events
abstract class AppContentEvent extends Equatable {
  const AppContentEvent();
  @override
  List<Object?> get props => [];
}

class LoadAppContent extends AppContentEvent {
  final int? tabId;
  final bool forceRefresh;

  const LoadAppContent({this.tabId, this.forceRefresh = false});

  @override
  List<Object?> get props => [tabId, forceRefresh];
}

class LoadCategoryScreenContent extends AppContentEvent {
  final bool forceRefresh;

  const LoadCategoryScreenContent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class _StreamDataUpdated extends AppContentEvent {
  final List<AppContent> contents;
  final int? tabId;
  final bool isStale;

  const _StreamDataUpdated(this.contents, {this.tabId, this.isStale = false});

  @override
  List<Object?> get props => [contents, tabId, isStale];
}

// States
abstract class AppContentState extends Equatable {
  const AppContentState();
  @override
  List<Object?> get props => [];
}

class AppContentInitial extends AppContentState {}

class AppContentLoading extends AppContentState {}

class AppContentLoaded extends AppContentState {
  final List<AppContent> contents;
  final int? tabId;
  final bool isStale;

  const AppContentLoaded({required this.contents, this.tabId, this.isStale = false});

  @override
  List<Object?> get props => [contents, tabId, isStale];
}

class AppContentError extends AppContentState {
  final String message;

  const AppContentError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AppContentBloc extends Bloc<AppContentEvent, AppContentState> {
  final GetAppContent getAppContent;
  final GetCategoryScreenContent? getCategoryScreenContent;
  final DataSyncService _dataSyncService;
  StreamSubscription? _streamSubscription;
  int? _currentTabId;
  String? _lastDataHash;

  AppContentBloc({required this.getAppContent, this.getCategoryScreenContent})
      : _dataSyncService = DataSyncService(),
        super(AppContentInitial()) {
    on<LoadAppContent>(_onLoadAppContent);
    on<LoadCategoryScreenContent>(_onLoadCategoryScreenContent);
    on<_StreamDataUpdated>(_onStreamDataUpdated);
  }

  String _generateDataHash(List<AppContent> data) {
    final buffer = StringBuffer();
    for (final item in data) {
      buffer.write('${item.id}_${item.sortOrder}_');
    }
    return buffer.toString().hashCode.toString();
  }

  void _subscribeToStream(int? tabId) {
    _streamSubscription?.cancel();
    _currentTabId = tabId;

    _streamSubscription = _dataSyncService.appContentStream(tabId)
        .distinct((prev, curr) {
          if (!prev.hasData || !curr.hasData) return false;
          return _generateDataHash(prev.data!) == _generateDataHash(curr.data!) &&
                 prev.isStale == curr.isStale;
        })
        .listen((dataState) {
          if (dataState.hasData && !isClosed) {
            final newHash = _generateDataHash(dataState.data!);

            if (_lastDataHash != newHash ||
                (state is AppContentLoaded &&
                 (state as AppContentLoaded).isStale != dataState.isStale)) {
              _lastDataHash = newHash;
              add(_StreamDataUpdated(dataState.data!, tabId: tabId, isStale: dataState.isStale));
            }
          }
        });
  }

  Future<void> _onLoadAppContent(
    LoadAppContent event,
    Emitter<AppContentState> emit,
  ) async {
    
    // Subscribe to stream for this tab if changed
    if (_currentTabId != event.tabId) {
      _subscribeToStream(event.tabId);
    }

    // Show loading on force refresh (pull-to-refresh)
    if (event.forceRefresh) {
      emit(AppContentLoading());
      
      final result = await getAppContent(
        tabId: event.tabId,
        forceRefresh: true,
      );

      result.fold(
        (failure) {
          emit(AppContentError(failure.message));
        },
        (contents) {
          _lastDataHash = _generateDataHash(contents);
          emit(AppContentLoaded(contents: contents, tabId: event.tabId));
        },
      );
      return;
    }

    // Check if we have cached data in DataSyncService for instant display
    final cachedState = _dataSyncService.appContentState(event.tabId);
    if (cachedState.hasData && cachedState.data!.isNotEmpty) {
      _lastDataHash = _generateDataHash(cachedState.data!);
      emit(AppContentLoaded(contents: cachedState.data!, tabId: event.tabId, isStale: true));
      
      // Fetch fresh data in background (don't await)
      getAppContent(tabId: event.tabId, forceRefresh: false).then((result) {
        result.fold(
          (_) {},
          (contents) {
            if (!isClosed && contents.isNotEmpty) {
              final newHash = _generateDataHash(contents);
              if (_lastDataHash != newHash) {
                _lastDataHash = newHash;
                add(_StreamDataUpdated(contents, tabId: event.tabId, isStale: false));
              }
            }
          },
        );
      });
      return;
    }

    // No cached data - show loading skeleton
    emit(AppContentLoading());

    final result = await getAppContent(
      tabId: event.tabId,
      forceRefresh: false,
    );

    result.fold(
      (failure) {
        emit(AppContentError(failure.message));
      },
      (contents) {
        _lastDataHash = _generateDataHash(contents);
        emit(AppContentLoaded(contents: contents, tabId: event.tabId));
      },
    );
  }

  Future<void> _onLoadCategoryScreenContent(
    LoadCategoryScreenContent event,
    Emitter<AppContentState> emit,
  ) async {
    if (getCategoryScreenContent == null) {
      emit(const AppContentError('Category screen content feature not available'));
      return;
    }
    
    // Use special tabId for category screen
    const categoryScreenTabId = -999;
    
    // Subscribe to stream for category screen if not already
    if (_currentTabId != categoryScreenTabId) {
      _subscribeToStream(categoryScreenTabId);
    }

    // Show loading on force refresh
    if (event.forceRefresh) {
      emit(AppContentLoading());
      
      final result = await getCategoryScreenContent!(forceRefresh: true);

      result.fold(
        (failure) {
          emit(AppContentError(failure.message));
        },
        (contents) {
          _lastDataHash = _generateDataHash(contents);
          emit(AppContentLoaded(contents: contents, tabId: categoryScreenTabId));
        },
      );
      return;
    }

    // Check cached data
    final cachedState = _dataSyncService.appContentState(categoryScreenTabId);
    if (cachedState.hasData && cachedState.data!.isNotEmpty) {
      _lastDataHash = _generateDataHash(cachedState.data!);
      emit(AppContentLoaded(contents: cachedState.data!, tabId: categoryScreenTabId, isStale: true));
      
      // Fetch fresh data in background
      getCategoryScreenContent!(forceRefresh: false).then((result) {
        result.fold(
          (_) {},
          (contents) {
            if (!isClosed && contents.isNotEmpty) {
              final newHash = _generateDataHash(contents);
              if (_lastDataHash != newHash) {
                _lastDataHash = newHash;
                add(_StreamDataUpdated(contents, tabId: categoryScreenTabId, isStale: false));
              }
            }
          },
        );
      });
      return;
    }

    // No cached data - show loading
    emit(AppContentLoading());

    final result = await getCategoryScreenContent!(forceRefresh: false);

    result.fold(
      (failure) {
        emit(AppContentError(failure.message));
      },
      (contents) {
        _lastDataHash = _generateDataHash(contents);
        emit(AppContentLoaded(contents: contents, tabId: categoryScreenTabId));
      },
    );
  }

  void _onStreamDataUpdated(
    _StreamDataUpdated event,
    Emitter<AppContentState> emit,
  ) {
    // Only update if the tab ID matches the current tab
    if (event.tabId == _currentTabId) {
      emit(AppContentLoaded(contents: event.contents, tabId: event.tabId, isStale: event.isStale));
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
