import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_config.dart';
import '../../domain/usecases/get_app_config.dart';

// Events
abstract class AppConfigEvent extends Equatable {
  const AppConfigEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppConfig extends AppConfigEvent {}

class RefreshAppConfig extends AppConfigEvent {}

// States
abstract class AppConfigState extends Equatable {
  const AppConfigState();

  @override
  List<Object?> get props => [];
}

class AppConfigInitial extends AppConfigState {}

class AppConfigLoading extends AppConfigState {}

class AppConfigLoaded extends AppConfigState {
  final AppConfig config;

  const AppConfigLoaded(this.config);

  @override
  List<Object?> get props => [config];
}

class AppConfigError extends AppConfigState {
  final String message;

  const AppConfigError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AppConfigBloc extends Bloc<AppConfigEvent, AppConfigState> {
  final GetAppConfig _getAppConfig;
  AppConfig? _currentConfig;

  AppConfigBloc(this._getAppConfig) : super(AppConfigInitial()) {
    on<LoadAppConfig>(_onLoadAppConfig);
    on<RefreshAppConfig>(_onRefreshAppConfig);
  }

  AppConfig? get currentConfig => _currentConfig;

  Future<void> _onLoadAppConfig(
    LoadAppConfig event,
    Emitter<AppConfigState> emit,
  ) async {
    emit(AppConfigLoading());

    final result = await _getAppConfig();
    result.fold(
      (failure) => emit(AppConfigError(failure.message)),
      (config) {
        _currentConfig = config;
        emit(AppConfigLoaded(config));
      },
    );
  }

  Future<void> _onRefreshAppConfig(
    RefreshAppConfig event,
    Emitter<AppConfigState> emit,
  ) async {
    final result = await _getAppConfig();
    result.fold(
      (failure) {
        // Keep current config on refresh failure
        if (_currentConfig != null) {
          emit(AppConfigLoaded(_currentConfig!));
        } else {
          emit(AppConfigError(failure.message));
        }
      },
      (config) {
        _currentConfig = config;
        // Always emit — even if config looks equal by Equatable,
        // force a fresh state so currency symbol updates propagate.
        emit(AppConfigInitial()); // reset first to break equality check
        emit(AppConfigLoaded(config));
      },
    );
  }
}
