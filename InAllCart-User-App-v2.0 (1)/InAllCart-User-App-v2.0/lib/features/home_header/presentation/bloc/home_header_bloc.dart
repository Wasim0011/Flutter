import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/home_header_config.dart';
import '../../domain/usecases/get_home_header_config.dart';

// Events
abstract class HomeHeaderEvent extends Equatable {
  const HomeHeaderEvent();
  @override
  List<Object?> get props => [];
}

class LoadHomeHeader extends HomeHeaderEvent {
  final bool forceRefresh;
  const LoadHomeHeader({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class SelectTab extends HomeHeaderEvent {
  final int tabId;
  const SelectTab(this.tabId);
  @override
  List<Object?> get props => [tabId];
}

class _StreamDataUpdated extends HomeHeaderEvent {
  final HomeHeaderConfig config;
  final bool isStale;
  const _StreamDataUpdated(this.config, {this.isStale = false});
  @override
  List<Object?> get props => [config, isStale];
}

// States
abstract class HomeHeaderState extends Equatable {
  const HomeHeaderState();
  @override
  List<Object?> get props => [];
}

class HomeHeaderInitial extends HomeHeaderState {}

class HomeHeaderLoading extends HomeHeaderState {}

class HomeHeaderLoaded extends HomeHeaderState {
  final HomeHeaderConfig config;
  final HomeHeaderTab selectedTab;
  final bool isStale;

  const HomeHeaderLoaded({
    required this.config,
    required this.selectedTab,
    this.isStale = false,
  });

  @override
  List<Object?> get props => [config, selectedTab, isStale];

  HomeHeaderLoaded copyWith({
    HomeHeaderConfig? config,
    HomeHeaderTab? selectedTab,
    bool? isStale,
  }) {
    return HomeHeaderLoaded(
      config: config ?? this.config,
      selectedTab: selectedTab ?? this.selectedTab,
      isStale: isStale ?? this.isStale,
    );
  }
}

class HomeHeaderError extends HomeHeaderState {
  final String message;
  const HomeHeaderError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class HomeHeaderBloc extends Bloc<HomeHeaderEvent, HomeHeaderState> {
  final GetHomeHeaderConfig _getHomeHeaderConfig;
  final DataSyncService _dataSyncService;
  StreamSubscription? _streamSubscription;
  String? _lastDataHash;

  HomeHeaderBloc(this._getHomeHeaderConfig)
      : _dataSyncService = DataSyncService(),
        super(_getInitialState()) {
    on<LoadHomeHeader>(_onLoadHomeHeader);
    on<SelectTab>(_onSelectTab);
    on<_StreamDataUpdated>(_onStreamDataUpdated);
    
    _subscribeToStream();
  }

  static HomeHeaderState _getInitialState() {
    final service = DataSyncService();
    if (service.homeHeaderState.hasData) {
      final config = service.homeHeaderState.data!;
      final defaultTab = config.defaultTab ?? const HomeHeaderTab.empty();
      return HomeHeaderLoaded(
        config: config, 
        selectedTab: defaultTab,
        isStale: true,
      );
    }
    return HomeHeaderInitial();
  }

  String _generateDataHash(HomeHeaderConfig config) {
    final buffer = StringBuffer();
    buffer.write('${config.tabsActive}_${config.backgroundActive}_${config.cardsActive}_');
    for (final tab in config.tabs) {
      final topBg = tab.topHeaderBackground;
      buffer.write('${tab.id}_${tab.name}_${tab.categoryId}_${tab.cardsHorizontal}_${tab.background?.url}_${topBg?.type}_${topBg?.color1}_${topBg?.color2}_${topBg?.style}_${topBg?.imageUrl}_${tab.cards.length}_');
    }
    return buffer.toString().hashCode.toString();
  }

  void _subscribeToStream() {
    _streamSubscription?.cancel();
    
    _streamSubscription = _dataSyncService.homeHeaderStream
        .distinct((prev, curr) {
          if (!prev.hasData || !curr.hasData) return false;
          return _generateDataHash(prev.data!) == _generateDataHash(curr.data!) &&
                 prev.isStale == curr.isStale;
        })
        .listen(
      (dataState) {
        if (dataState.hasData && !isClosed) {
          final newHash = _generateDataHash(dataState.data!);
          
          if (_lastDataHash != newHash || 
              (state is HomeHeaderLoaded && (state as HomeHeaderLoaded).isStale != dataState.isStale)) {
            _lastDataHash = newHash;
            add(_StreamDataUpdated(dataState.data!, isStale: dataState.isStale));
          }
        }
      },
    );
  }

  Future<void> _onLoadHomeHeader(
    LoadHomeHeader event,
    Emitter<HomeHeaderState> emit,
  ) async {
    
    // Show loading on force refresh (pull-to-refresh)
    if (event.forceRefresh) {
      emit(HomeHeaderLoading());
      
      final result = await _getHomeHeaderConfig(forceRefresh: true);

      result.fold(
        (failure) {
          emit(HomeHeaderError(failure.message));
        },
        (config) {
          _lastDataHash = _generateDataHash(config);
          final defaultTab = config.defaultTab ?? const HomeHeaderTab.empty();
          emit(HomeHeaderLoaded(config: config, selectedTab: defaultTab));
        },
      );
      return;
    }

    // Check if we have cached data in DataSyncService for instant display
    final cachedState = _dataSyncService.homeHeaderState;
    if (cachedState.hasData) {
      final cachedConfig = cachedState.data!;
      final defaultTab = cachedConfig.defaultTab ?? const HomeHeaderTab.empty();
      
      // Preserve current selected tab if we have one
      HomeHeaderTab selectedTab = defaultTab;
      if (state is HomeHeaderLoaded) {
        final currentSelectedId = (state as HomeHeaderLoaded).selectedTab.id;
        for (final tab in cachedConfig.tabs) {
          if (tab.id == currentSelectedId) {
            selectedTab = tab;
            break;
          }
        }
      }
      _lastDataHash = _generateDataHash(cachedConfig);
      emit(HomeHeaderLoaded(config: cachedConfig, selectedTab: selectedTab, isStale: true));
      
      // Refresh in background (don't await)
      _getHomeHeaderConfig(forceRefresh: false).then((result) {
        result.fold(
          (_) {},
          (config) {
            if (!isClosed) {
              final newHash = _generateDataHash(config);
              if (_lastDataHash != newHash) {
                _lastDataHash = newHash;
                add(_StreamDataUpdated(config, isStale: false));
              }
            }
          },
        );
      });
      return;
    }

    // No cached data - show loading skeleton
    emit(HomeHeaderLoading());

    final result = await _getHomeHeaderConfig(forceRefresh: false);

    result.fold(
      (failure) {
        emit(HomeHeaderError(failure.message));
      },
      (config) {
        _lastDataHash = _generateDataHash(config);
        final defaultTab = config.defaultTab ?? const HomeHeaderTab.empty();
        emit(HomeHeaderLoaded(config: config, selectedTab: defaultTab));
      },
    );
  }

  void _onSelectTab(SelectTab event, Emitter<HomeHeaderState> emit) {
    if (state is HomeHeaderLoaded) {
      final currentState = state as HomeHeaderLoaded;

      // Video controller lifecycle is owned ENTIRELY by the HeaderBackground
      // widget (via VideoCacheService). Do NOT touch it here — doing so causes
      // a double-release that corrupts the reference count.

      HomeHeaderTab? selectedTab;

      for (final tab in currentState.config.tabs) {
        if (tab.id == event.tabId) {
          selectedTab = tab;
          break;
        }
      }

      emit(currentState.copyWith(selectedTab: selectedTab ?? currentState.selectedTab));
    }
  }

  void _onStreamDataUpdated(_StreamDataUpdated event, Emitter<HomeHeaderState> emit) {
    // Preserve selected tab if it still exists in new config
    HomeHeaderTab selectedTab = event.config.defaultTab ?? const HomeHeaderTab.empty();
    
    if (state is HomeHeaderLoaded) {
      final currentSelectedId = (state as HomeHeaderLoaded).selectedTab.id;
      for (final tab in event.config.tabs) {
        if (tab.id == currentSelectedId) {
          selectedTab = tab;
          break;
        }
      }
    }
    
    emit(HomeHeaderLoaded(
      config: event.config,
      selectedTab: selectedTab,
      isStale: event.isStale,
    ));
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    // Video controllers are owned by the HeaderBackground widget lifecycle.
    // Do not call VideoCacheService().clearAll() here — it would dispose
    // controllers that the widget might still be actively displaying.
    return super.close();
  }
}
