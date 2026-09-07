import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../models/ai_chat_message_model.dart';

abstract class AiLocalDataSource {
  Future<List<AiChatMessage>> getChatHistory();
  Future<void> saveMessage(AiChatMessage message);
  Future<void> clearHistory();
}

class AiLocalDataSourceImpl implements AiLocalDataSource {
  final Box<String> chatBox;
  static const String _historyKey = 'ai_chat_history';
  static const int _maxHistory = 50;

  AiLocalDataSourceImpl(this.chatBox);

  @override
  Future<List<AiChatMessage>> getChatHistory() async {
    final rawData = chatBox.get(_historyKey);
    if (rawData == null) return [];
    
    final List<dynamic> decoded = jsonDecode(rawData);
    return decoded.map((e) => AiChatMessageModel.fromJson(e).toEntity()).toList();
  }

  @override
  Future<void> saveMessage(AiChatMessage message) async {
    final history = await getChatHistory();
    history.add(message);
    
    // Keep only last N messages
    final trimmed = history.length > _maxHistory 
        ? history.sublist(history.length - _maxHistory)
        : history;
        
    final encoded = jsonEncode(trimmed.map((e) => AiChatMessageModel.fromEntity(e).toJson()).toList());
    await chatBox.put(_historyKey, encoded);
  }

  @override
  Future<void> clearHistory() async {
    await chatBox.delete(_historyKey);
  }
}
