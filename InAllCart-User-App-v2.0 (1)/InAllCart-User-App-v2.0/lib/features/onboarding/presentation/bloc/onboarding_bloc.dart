import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app_config/domain/entities/app_config.dart';
import '../../domain/usecases/complete_onboarding.dart';
import '../../domain/usecases/get_onboarding_screens.dart';

// Events
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class LoadOnboardingScreens extends OnboardingEvent {}

class NextPage extends OnboardingEvent {}

class PreviousPage extends OnboardingEvent {}

class GoToPage extends OnboardingEvent {
  final int page;

  const GoToPage(this.page);

  @override
  List<Object?> get props => [page];
}

class SkipOnboarding extends OnboardingEvent {}

class CompleteOnboardingEvent extends OnboardingEvent {}

// States
abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingLoaded extends OnboardingState {
  final List<OnboardingScreen> screens;
  final int currentPage;
  final bool isLastPage;

  const OnboardingLoaded({
    required this.screens,
    required this.currentPage,
    required this.isLastPage,
  });

  @override
  List<Object?> get props => [screens, currentPage, isLastPage];

  OnboardingLoaded copyWith({
    List<OnboardingScreen>? screens,
    int? currentPage,
    bool? isLastPage,
  }) {
    return OnboardingLoaded(
      screens: screens ?? this.screens,
      currentPage: currentPage ?? this.currentPage,
      isLastPage: isLastPage ?? this.isLastPage,
    );
  }
}

class OnboardingCompleted extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetOnboardingScreens _getOnboardingScreens;
  final CompleteOnboarding _completeOnboarding;

  OnboardingBloc(this._getOnboardingScreens, this._completeOnboarding)
      : super(OnboardingInitial()) {
    on<LoadOnboardingScreens>(_onLoadScreens);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<GoToPage>(_onGoToPage);
    on<SkipOnboarding>(_onSkip);
    on<CompleteOnboardingEvent>(_onComplete);
  }

  Future<void> _onLoadScreens(
    LoadOnboardingScreens event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());

    final result = await _getOnboardingScreens();
    result.fold(
      (failure) => emit(OnboardingError(failure.message)),
      (screens) => emit(OnboardingLoaded(
        screens: screens,
        currentPage: 0,
        isLastPage: screens.length <= 1,
      )),
    );
  }

  void _onNextPage(NextPage event, Emitter<OnboardingState> emit) {
    final currentState = state;
    if (currentState is OnboardingLoaded) {
      final nextPage = currentState.currentPage + 1;
      if (nextPage < currentState.screens.length) {
        emit(currentState.copyWith(
          currentPage: nextPage,
          isLastPage: nextPage == currentState.screens.length - 1,
        ));
      } else {
        add(CompleteOnboardingEvent());
      }
    }
  }

  void _onPreviousPage(PreviousPage event, Emitter<OnboardingState> emit) {
    final currentState = state;
    if (currentState is OnboardingLoaded && currentState.currentPage > 0) {
      emit(currentState.copyWith(
        currentPage: currentState.currentPage - 1,
        isLastPage: false,
      ));
    }
  }

  void _onGoToPage(GoToPage event, Emitter<OnboardingState> emit) {
    final currentState = state;
    if (currentState is OnboardingLoaded) {
      if (event.page >= 0 && event.page < currentState.screens.length) {
        emit(currentState.copyWith(
          currentPage: event.page,
          isLastPage: event.page == currentState.screens.length - 1,
        ));
      }
    }
  }

  Future<void> _onSkip(
    SkipOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    await _completeOnboarding();
    emit(OnboardingCompleted());
  }

  Future<void> _onComplete(
    CompleteOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    await _completeOnboarding();
    emit(OnboardingCompleted());
  }
}
