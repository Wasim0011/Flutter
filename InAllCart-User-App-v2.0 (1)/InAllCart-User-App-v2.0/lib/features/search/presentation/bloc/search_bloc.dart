import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import '../../../products/domain/usecases/suggest_products.dart';
import '../../../../core/services/storage_service.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object> get props => [query];
}

class LoadSearchHistory extends SearchEvent {}

class AddToHistory extends SearchEvent {
  final String query;
  const AddToHistory(this.query);
  @override
  List<Object> get props => [query];
}

class RemoveFromHistory extends SearchEvent {
  final String query;
  const RemoveFromHistory(this.query);
  @override
  List<Object> get props => [query];
}

class ClearHistory extends SearchEvent {}

class SearchReset extends SearchEvent {}

// State
abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchHistoryLoaded extends SearchState {
  final List<String> history;
  const SearchHistoryLoaded(this.history);
  @override
  List<Object> get props => [history];
}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<dynamic> products;
  final List<dynamic> categories;
  
  const SearchLoaded({required this.products, required this.categories});
  
  @override
  List<Object> get props => [products, categories];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SuggestProducts _suggestProducts;
  final StorageService _storageService;

  SearchBloc(this._suggestProducts, this._storageService) : super(SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: _debounce(const Duration(milliseconds: 300)));
    on<LoadSearchHistory>(_onLoadHistory);
    on<AddToHistory>(_onAddToHistory);
    on<RemoveFromHistory>(_onRemoveFromHistory);
    on<ClearHistory>(_onClearHistory);
    on<SearchReset>(_onReset);
  }

  EventTransformer<T> _debounce<T>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
  }

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    if (event.query.trim().length < 2) {
      add(LoadSearchHistory());
      return;
    }

    emit(SearchLoading());
    
    final result = await _suggestProducts(event.query);
    
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (data) {
        emit(SearchLoaded(
          products: data['products'] ?? [],
          categories: data['categories'] ?? [],
        ));
      }
    );
  }

  void _onLoadHistory(LoadSearchHistory event, Emitter<SearchState> emit) {
    final history = _storageService.getSearchHistory();
    if (history.isEmpty) {
      emit(SearchInitial());
    } else {
      emit(SearchHistoryLoaded(history));
    }
  }

  Future<void> _onAddToHistory(AddToHistory event, Emitter<SearchState> emit) async {
    await _storageService.addToSearchHistory(event.query);
  }

  Future<void> _onRemoveFromHistory(RemoveFromHistory event, Emitter<SearchState> emit) async {
    await _storageService.removeFromSearchHistory(event.query);
    add(LoadSearchHistory());
  }

  Future<void> _onClearHistory(ClearHistory event, Emitter<SearchState> emit) async {
    await _storageService.clearSearchHistory();
    emit(SearchInitial());
  }
  
  void _onReset(SearchReset event, Emitter<SearchState> emit) {
    add(LoadSearchHistory());
  }
}
