import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../../../core/services/storage_service.dart';

// Events
abstract class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessage extends AiChatEvent {
  final String message;
  final String? image;

  const SendMessage(this.message, {this.image});

  @override
  List<Object?> get props => [message, image];
}

class LoadChatHistory extends AiChatEvent {}

class RemoveRecentQuery extends AiChatEvent {
  final String query;
  const RemoveRecentQuery(this.query);
  @override
  List<Object?> get props => [query];
}

class ClearChat extends AiChatEvent {}

// States
class AiChatState extends Equatable {
  final List<AiChatMessage> messages;
  final List<String> recentQueries;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.recentQueries = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    List<String>? recentQueries,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      recentQueries: recentQueries ?? this.recentQueries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [messages, recentQueries, isLoading, error];
}

// BLoC
class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiRepository repository;
  final StorageService storageService;

  AiChatBloc(this.repository, this.storageService) : super(const AiChatState()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendMessage>(_onSendMessage);
    on<RemoveRecentQuery>(_onRemoveRecentQuery);
    on<ClearChat>(_onClearChat);
  }

  Future<void> _onLoadChatHistory(LoadChatHistory event, Emitter<AiChatState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    final recentQueries = storageService.getAiHistory();
    
    final result = await repository.getChatHistory();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message, recentQueries: recentQueries)),
      (messages) => emit(state.copyWith(isLoading: false, messages: messages, recentQueries: recentQueries)),
    );
  }

  Future<void> _onRemoveRecentQuery(RemoveRecentQuery event, Emitter<AiChatState> emit) async {
    await storageService.removeFromAiHistory(event.query);
    final recentQueries = storageService.getAiHistory();
    emit(state.copyWith(recentQueries: recentQueries));
  }

  Future<void> _onClearChat(ClearChat event, Emitter<AiChatState> emit) async {
    await repository.clearHistory();
    await storageService.clearAiHistory();
    emit(const AiChatState());
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<AiChatState> emit) async {
    // 1. Calculate history BEFORE adding current message
    final history = state.messages
        .where((m) => !m.hasError)
        .map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text
        })
        .toList();

    // 2. Add to recent queries
    await storageService.addToAiHistory(event.message);
    final recentQueries = storageService.getAiHistory();

    final userMessage = AiChatMessage(
      text: event.message,
      isUser: true,
      image: event.image,
      timestamp: DateTime.now(),
    );

    // 3. Save user message locally
    await repository.saveMessage(userMessage);

    final updatedMessages = List<AiChatMessage>.from(state.messages)..add(userMessage);
    
    emit(state.copyWith(
      messages: updatedMessages,
      recentQueries: recentQueries,
      isLoading: true,
      error: null,
    ));

    final result = await repository.sendMessage(event.message, history: history, image: event.image);

    await result.fold(
      (failure) async {
        emit(state.copyWith(
          isLoading: false,
          error: failure.message,
        ));
      },
      (data) async {
        final aiMessage = AiChatMessage(
          text: data.message,
          isUser: false,
          items: data.items,
          timestamp: DateTime.now(),
        );

        // Save AI response locally
        await repository.saveMessage(aiMessage);

        final finalMessages = List<AiChatMessage>.from(state.messages)..add(aiMessage);
        emit(state.copyWith(
          messages: finalMessages,
          isLoading: false,
        ));
      },
    );
  }
}
