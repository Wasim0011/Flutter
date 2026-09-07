import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/static_pages_remote_datasource.dart';
import '../../domain/entities/static_page.dart';

// ── State ─────────────────────────────────────────────────────────────────────

abstract class StaticPagesState {}

class StaticPagesInitial extends StaticPagesState {}

class StaticPagesLoading extends StaticPagesState {}

class StaticPagesLoaded extends StaticPagesState {
  final List<StaticPage> pages;
  StaticPagesLoaded(this.pages);
}

class StaticPagesError extends StaticPagesState {
  final String message;
  StaticPagesError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class StaticPagesCubit extends Cubit<StaticPagesState> {
  final StaticPagesRemoteDataSource _dataSource;

  StaticPagesCubit(this._dataSource) : super(StaticPagesInitial());

  Future<void> load() async {
    emit(StaticPagesLoading());
    try {
      final pages = await _dataSource.getPages();
      emit(StaticPagesLoaded(pages));
    } catch (e) {
      emit(StaticPagesError(e.toString()));
    }
  }
}
