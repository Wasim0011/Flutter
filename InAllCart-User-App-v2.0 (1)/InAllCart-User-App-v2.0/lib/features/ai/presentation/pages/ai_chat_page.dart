import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/simple_product_card.dart';
import '../../../../core/router/routes.dart';
import '../bloc/ai_chat_bloc.dart';
import '../../domain/entities/ai_chat_message.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AiChatBloc>().add(LoadChatHistory());
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        
        // Double check after a small delay as items might still be sizing
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Shopping Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.read<AiChatBloc>().add(ClearChat()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<AiChatBloc, AiChatState>(
              listener: (context, state) {
                if (state.messages.isNotEmpty || state.isLoading) {
                  _scrollToBottom();
                }
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                final messages = state.messages;
                final isLoading = state.isLoading;

                if (messages.isEmpty && !isLoading) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  key: ValueKey('chat_list_${messages.length}'),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _ChatBubble(
                      key: ValueKey('msg_${messages[index].timestamp.millisecondsSinceEpoch}'),
                      message: messages[index],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final state = context.watch<AiChatBloc>().state;
    final recentHistory = state.recentQueries;
    
    final List<Map<String, String>> suggestions = [
      {'text': 'Best snacks for kids', 'emoji': '🍪'},
      {'text': 'Healthy breakfast ideas', 'emoji': '🥑'},
      {'text': 'Budget groceries under ₹500', 'emoji': '💰'},
      {'text': 'Trending products today', 'emoji': '🔥'},
      {'text': 'Best deals near me', 'emoji': '📍'},
      {'text': 'Organic food options', 'emoji': '🌿'},
      {'text': 'Gift ideas for coffee lovers', 'emoji': '☕'},
      {'text': 'Daily essentials for home', 'emoji': '🏠'},
      {'text': 'Healthy snacks for work', 'emoji': '💼'},
      {'text': 'Top-rated products', 'emoji': '⭐'},
      {'text': 'Quick & easy meal items', 'emoji': '🍳'},
      {'text': 'Best value products', 'emoji': '💎'},
      {'text': 'Popular items this week', 'emoji': '📈'},
      {'text': 'Discounted items you’ll love', 'emoji': '🏷️'},
      {'text': 'New arrivals you should check', 'emoji': '✨'},
    ];

    // Split suggestions into 3 rows
    final row1 = suggestions.sublist(0, 5);
    final row2 = suggestions.sublist(5, 10);
    final row3 = suggestions.sublist(10, 15);

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          SvgPicture.asset(
            'assets/icons/ai_assistant.svg',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 24),
          const Text(
            'How can I help you today?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me anything about products, recipes, or deals!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          
          if (recentHistory.isNotEmpty) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    'Recent Interactions',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.read<AiChatBloc>().add(ClearChat()),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: recentHistory.length,
                itemBuilder: (context, index) {
                  final query = recentHistory[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InputChip(
                      avatar: const Icon(Icons.north_west, size: 14),
                      label: Text(query, style: const TextStyle(fontSize: 13)),
                      onPressed: () => _sendMessage(query),
                      onDeleted: () => context.read<AiChatBloc>().add(RemoveRecentQuery(query)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          
          // Row 1: Right to Left
          _AutoScrollingRow(
            items: row1,
            speed: 20,
            onTap: (text) => _sendMessage(text),
          ),
          const SizedBox(height: 16),
          
          // Row 2: Left to Right
          _AutoScrollingRow(
            items: row2,
            speed: 25,
            direction: AxisDirection.left, // Reverse visual flow
            onTap: (text) => _sendMessage(text),
          ),
          const SizedBox(height: 16),
          
          // Row 3: Right to Left
          _AutoScrollingRow(
            items: row3,
            speed: 22,
            onTap: (text) => _sendMessage(text),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(_controller.text),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<AiChatBloc>().add(SendMessage(text));
    _controller.clear();
  }
}

class _ChatBubble extends StatelessWidget {
  final AiChatMessage message;

  const _ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: message.isUser ? AppColors.primary : Colors.grey[200],
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(16),
                bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(0),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
          ),
          if (message.items != null && message.items!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: message.items!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = message.items![index];
                  return SizedBox(
                    width: 160,
                    child: SimpleProductCard(
                      productId: product.id,
                      name: product.name,
                      price: product.price.amount,
                      comparePrice: product.price.comparePrice,
                      imageUrl: product.imageUrl,
                      unit: product.unit,
                      rating: product.rating,
                      reviewCount: product.reviewCount,
                      onTap: () => context.push(Routes.product(product.id.toString()), extra: product),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _AutoScrollingRow extends StatefulWidget {
  final List<Map<String, String>> items;
  final double speed;
  final AxisDirection direction;
  final ValueChanged<String> onTap;

  const _AutoScrollingRow({
    required this.items,
    this.speed = 20, // pixels per second
    this.direction = AxisDirection.right,
    required this.onTap,
  });

  @override
  State<_AutoScrollingRow> createState() => _AutoScrollingRowState();
}

class _AutoScrollingRowState extends State<_AutoScrollingRow> with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final Ticker _ticker;
  double _scrollOffset = 0.0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _ticker = createTicker(_onTick);
    
    // Use a post-frame callback to ensure clients are attached before starting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ticker.start();
      }
    });
  }

  void _onTick(Duration elapsed) {
    if (!_scrollController.hasClients || _isPaused) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    // Calculate pixels to move per frame (assuming 60fps roughly, or using elapsed)
    // For simplicity, fixed small increment works well for "cloud" drift
    const double delta = 0.5; 

    _scrollOffset += delta;

    if (_scrollOffset >= maxScroll) {
      _scrollOffset = 0.0;
      _scrollController.jumpTo(0);
    } else {
      _scrollController.jumpTo(_scrollOffset);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reverse = widget.direction == AxisDirection.left;

    return Listener(
      onPointerDown: (_) => _isPaused = true,
      onPointerUp: (_) => _isPaused = false,
      onPointerCancel: (_) => _isPaused = false,
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          reverse: reverse, 
          physics: const NeverScrollableScrollPhysics(), 
          itemCount: 1000, 
          itemBuilder: (context, index) {
            final item = widget.items[index % widget.items.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _SuggestionChip(
                label: '${item['emoji']} ${item['text']}',
                onTap: () => widget.onTap(item['text']!),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C63FF), // Primary blue-ish
            Color(0xFFFF6584), // Pink/Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(1.5), // Border width
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95), // Inner background
                borderRadius: BorderRadius.circular(29),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
