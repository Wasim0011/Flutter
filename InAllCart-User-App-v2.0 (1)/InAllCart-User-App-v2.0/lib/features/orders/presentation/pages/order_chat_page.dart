import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/firebase_chat_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../data/models/order_chat_model.dart';
import '../../domain/entities/order_chat.dart';

class OrderChatPage extends StatefulWidget {
  final int orderId;
  final String chatType; // 'customer_delivery' or 'customer_seller'

  const OrderChatPage({
    super.key,
    required this.orderId,
    required this.chatType,
  });

  @override
  State<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _apiClient = getIt<ApiClient>();
  final _storage = getIt<StorageService>();
  final _chatService = FirebaseChatService.instance;

  OrderChat? _chat;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  String? _errorMessage;
  int? _currentUserId;
  String? _currentUserName;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;
  bool _shouldScrollToBottom = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;

    try {
      // Get current user info
      final userJson = _storage.getUser();
      if (userJson != null) {
        _currentUserId = userJson['id'] as int?;
        _currentUserName = userJson['name'] as String?;
      }

      // Initialize chat session
      final response = await _apiClient.post(
        '/api/v1/orders/${widget.orderId}/chat/init',
        data: {'chat_type': widget.chatType},
      );

      final Map<String, dynamic> responseData;
      if (response is Map<String, dynamic>) {
        responseData = response;
      } else {
        responseData = response.data as Map<String, dynamic>;
      }

      if (responseData['success'] == true) {
        final data = responseData['data'];
        final chatModel = OrderChatModel.fromJson(data);

        if (mounted) {
          setState(() {
            _chat = chatModel;
            _isLoading = false;
          });

          _listenToTyping();
          _markAsRead();
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to initialize chat');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _listenToTyping() {
    if (_chat == null || _currentUserId == null) return;

    final otherUserId = _chat!.customer.id == _currentUserId
        ? _chat!.participant?.id
        : _chat!.customer.id;

    if (otherUserId == null) return;

    _typingSubscription?.cancel();
    _typingSubscription = _chatService
        .listenToTypingStatus(
          firebaseChatId: _chat!.firebaseChatId,
          otherUserId: otherUserId,
        )
        .listen((isTyping) {
          if (mounted) {
            setState(() {
              _isTyping = isTyping;
            });
          }
        });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chat == null) return;
    if (_currentUserId == null || _currentUserName == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      // Send to Firebase
      await _chatService.sendMessage(
        firebaseChatId: _chat!.firebaseChatId,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        message: message,
      );

      // Notify backend to send push notification
      await _apiClient.post(
        '/api/v1/orders/${widget.orderId}/chat/${widget.chatType}/notify',
        data: {'message': message, 'is_viewing': false},
      );

      // Stop typing indicator
      await _chatService.setTypingStatus(
        firebaseChatId: _chat!.firebaseChatId,
        userId: _currentUserId!,
        isTyping: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _markAsRead() async {
    if (_chat == null || _currentUserId == null) return;

    try {
      // Mark in Firebase
      await _chatService.markMessagesAsRead(
        firebaseChatId: _chat!.firebaseChatId,
        currentUserId: _currentUserId!,
      );

      // Mark in backend
      await _apiClient.post(
        '/api/v1/orders/${widget.orderId}/chat/${widget.chatType}/read',
      );
    } catch (e) {
      // Silently fail
    }
  }

  bool _isMeTyping = false;

  void _onTyping(String text) {
    if (_chat == null || _currentUserId == null) return;

    // Cancel previous timer
    _typingTimer?.cancel();

    // Only set typing status to true if not already typing
    if (!_isMeTyping) {
      _isMeTyping = true;
      _chatService.setTypingStatus(
        firebaseChatId: _chat!.firebaseChatId,
        userId: _currentUserId!,
        isTyping: true,
      );
    }

    // Clear typing status after 3 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isMeTyping = false;
      _chatService.setTypingStatus(
        firebaseChatId: _chat!.firebaseChatId,
        userId: _currentUserId!,
        isTyping: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: GlobalAppBar(title: 'Chat'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_chat == null) {
      return _buildErrorState();
    }

    final otherParticipant = _chat!.customer.id == _currentUserId
        ? _chat!.participant
        : _chat!.customer;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(otherParticipant),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildChatInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatParticipant? otherParticipant) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: otherParticipant?.avatar != null
                ? CachedImage(
                    imageUrl: otherParticipant!.avatar!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(18),
                  )
                : Text(
                    otherParticipant?.name[0].toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherParticipant?.name ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (_isTyping)
                  const Text(
                    'typing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (otherParticipant?.phone != null)
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.primary),
            tooltip: 'Call ${otherParticipant?.name ?? 'participant'}',
            onPressed: () async {
              final phone = otherParticipant!.phone!;
              final uri = Uri(scheme: 'tel', path: phone);
              final messenger = ScaffoldMessenger.of(context);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text('Cannot call $phone')),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: const GlobalAppBar(title: 'Chat'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 56,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Chat not available',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessageModel>>(
      stream: _chatService.listenToMessages(_chat!.firebaseChatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final messages = snapshot.data!;

        // Handle auto-scroll to bottom
        if (_shouldScrollToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
              _shouldScrollToBottom = false;
            }
          });
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;
            final showDate =
                index == 0 ||
                !_isSameDay(message.timestamp, messages[index - 1].timestamp);

            return Column(
              children: [
                if (showDate) _buildDateDivider(message.timestamp),
                _buildMessageBubble(message, isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  onChanged: _onTyping,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6A11CB)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSending
              ? null
              : () {
                  _shouldScrollToBottom = true;
                  _sendMessage();
                },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? Colors.blue[200]
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
