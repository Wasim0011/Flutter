import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/firebase_chat_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/orders/data/models/order_chat_model.dart';
import '../../data/models/support_ticket_model.dart';
import '../../data/support_repository.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  final _repo = GetIt.I<SupportRepository>();
  final _storage = GetIt.I<StorageService>();
  final _chatService = FirebaseChatService.instance;
  final _msgCtrl = TextEditingController();

  // Separate scroll controllers per tab to avoid "attached to multiple" error
  final _restScrollCtrl = ScrollController();
  final _liveScrollCtrl = ScrollController();

  SupportTicket? _ticket;
  bool _loading = true;
  bool _sending = false;
  bool _isAgentTyping = false;
  bool _liveChatMode = false;
  String? _error;

  int? _currentUserId;
  String? _currentUserName;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;
  bool _isMeTyping = false;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadUser();
    _loadTicket();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _restScrollCtrl.dispose();
    _liveScrollCtrl.dispose();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _loadUser() {
    final userJson = _storage.getUser();
    if (userJson != null) {
      _currentUserId = userJson['id'] as int?;
      _currentUserName = userJson['name'] as String?;
    }
  }

  Future<void> _loadTicket() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ticket = await _repo.getTicket(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _loading = false;
        });
        // Scroll REST messages to bottom after load
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollRestToBottom());
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── REST message send ──────────────────────────────────────────────────────
  Future<void> _sendRestMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _ticket == null) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      final msg = await _repo.sendMessage(ticketId: _ticket!.id, message: text);
      if (mounted) {
        setState(() {
          _ticket = SupportTicket(
            id: _ticket!.id,
            ticketNumber: _ticket!.ticketNumber,
            subject: _ticket!.subject,
            description: _ticket!.description,
            status: _ticket!.status,
            priority: _ticket!.priority,
            firebaseChatId: _ticket!.firebaseChatId,
            category: _ticket!.category,
            messages: [..._ticket!.messages, msg],
            createdAt: _ticket!.createdAt,
            updatedAt: DateTime.now(),
          );
          _sending = false;
        });
        _scrollRestToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Firebase message send ──────────────────────────────────────────────────
  Future<void> _sendFirebaseMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _ticket?.firebaseChatId == null || _currentUserId == null) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      await _chatService.sendSupportMessage(
        firebaseChatId: _ticket!.firebaseChatId!,
        senderId: _currentUserId!,
        senderName: _currentUserName ?? 'User',
        message: text,
      );
      // Clear typing indicator
      await _chatService.setSupportTypingStatus(
        firebaseChatId: _ticket!.firebaseChatId!,
        userId: _currentUserId!,
        isTyping: false,
      );
      _isMeTyping = false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Enable live chat ───────────────────────────────────────────────────────
  void _enableLiveChat() {
    if (_ticket?.firebaseChatId == null) return;

    // Ensure Firebase is initialized before starting live chat
    if (!_chatService.isInitialized) {
      _chatService.initialize().then((_) {
        if (mounted) _startLiveChat();
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Firebase not ready: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
      return;
    }

    _startLiveChat();
  }

  void _startLiveChat() {
    setState(() => _liveChatMode = true);
    _tabCtrl.animateTo(1);

    // Cancel any existing subscription before creating a new one
    _typingSubscription?.cancel();
    _typingSubscription = _chatService
        .listenToSupportTyping(
          firebaseChatId: _ticket!.firebaseChatId!,
          currentUserId: _currentUserId ?? 0,
        )
        .listen((isTyping) {
          if (mounted) setState(() => _isAgentTyping = isTyping);
        });
  }

  // ── Typing indicator ───────────────────────────────────────────────────────
  void _onTyping(String text) {
    if (_ticket?.firebaseChatId == null || _currentUserId == null) return;
    _typingTimer?.cancel();
    if (!_isMeTyping) {
      _isMeTyping = true;
      _chatService.setSupportTypingStatus(
        firebaseChatId: _ticket!.firebaseChatId!,
        userId: _currentUserId!,
        isTyping: true,
      );
    }
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isMeTyping = false;
      _chatService.setSupportTypingStatus(
        firebaseChatId: _ticket!.firebaseChatId!,
        userId: _currentUserId!,
        isTyping: false,
      );
    });
  }

  void _scrollRestToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_restScrollCtrl.hasClients) {
        _restScrollCtrl.animateTo(
          _restScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollLiveToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_liveScrollCtrl.hasClients) {
        _liveScrollCtrl.jumpTo(_liveScrollCtrl.position.maxScrollExtent);
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null || _ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Support')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_error ?? 'Ticket not found',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Messages'),
                Tab(text: 'Live Chat'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildMessagesTab(),
                _buildLiveChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final color = _statusColor(_ticket!.status);
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _ticket!.ticketNumber,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _ticket!.statusLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
      actions: [
        if (_ticket!.isOpen && _ticket!.firebaseChatId != null && !_liveChatMode)
          TextButton.icon(
            onPressed: _enableLiveChat,
            icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: AppColors.primary),
            label: const Text(
              'Live',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
      ],
    );
  }

  // ── Messages tab (REST) ────────────────────────────────────────────────────
  Widget _buildMessagesTab() {
    return Column(
      children: [
        Expanded(
          child: _ticket!.messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  controller: _restScrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _ticket!.messages.length,
                  itemBuilder: (_, i) => _RestMessageBubble(
                    message: _ticket!.messages[i],
                    isMe: !_ticket!.messages[i].isAdmin,
                  ),
                ),
        ),
        if (_ticket!.isOpen)
          _buildInput(onSend: _sendRestMessage)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Ticket is ${_ticket!.statusLabel} — no new messages',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Live Chat tab (Firebase) ───────────────────────────────────────────────
  Widget _buildLiveChatTab() {
    if (_ticket!.firebaseChatId == null) {
      return const Center(
        child: Text(
          'Live chat not available for this ticket',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (!_liveChatMode) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Live Chat',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect with a support agent in real time.\nMessages appear instantly.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _ticket!.isOpen ? _enableLiveChat : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _ticket!.isOpen ? 'Start Live Chat' : 'Ticket is closed',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Typing indicator banner
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isAgentTyping
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: AppColors.primary.withValues(alpha: 0.06),
                  child: const Text(
                    'Agent is typing…',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessageModel>>(
            stream: _chatService.listenToSupportMessages(_ticket!.firebaseChatId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet — say hello!',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              // Auto-scroll on new messages
              _scrollLiveToBottom();

              return ListView.builder(
                controller: _liveScrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  final isMe = msg.senderId == _currentUserId;
                  final showDate = i == 0 ||
                      !_isSameDay(msg.timestamp, messages[i - 1].timestamp);
                  return Column(
                    children: [
                      if (showDate) _buildDateDivider(msg.timestamp),
                      _FirebaseMessageBubble(message: msg, isMe: isMe),
                    ],
                  );
                },
              );
            },
          ),
        ),
        if (_ticket!.isOpen)
          _buildInput(onSend: _sendFirebaseMessage, onTyping: _onTyping)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: const Text(
              'Ticket is closed',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
      ],
    );
  }

  // ── Shared input bar ───────────────────────────────────────────────────────
  Widget _buildInput({
    required VoidCallback onSend,
    ValueChanged<String>? onTyping,
  }) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  onChanged: onTyping,
                  decoration: const InputDecoration(
                    hintText: 'Type a message…',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sending
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final label =
        msgDate == today ? 'Today' : DateFormat('MMM dd, yyyy').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.warning;
      case 'waiting_user':
        return AppColors.info;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }
}

// ── REST message bubble ────────────────────────────────────────────────────
class _RestMessageBubble extends StatelessWidget {
  final SupportMessage message;
  final bool isMe;

  const _RestMessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.support_agent_rounded,
                  size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
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
                        message.user?.name ?? 'Support Agent',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('hh:mm a').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textTertiary,
                    ),
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
}

// ── Firebase message bubble ────────────────────────────────────────────────
class _FirebaseMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const _FirebaseMessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.textPrimary,
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
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
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
}
