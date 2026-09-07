import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/home_header_config.dart';

class QuickAccessCards extends StatefulWidget {
  final List<HomeHeaderCard> cards;
  final bool isHorizontal;
  final ValueChanged<HomeHeaderCard> onCardTap;

  const QuickAccessCards({
    super.key,
    required this.cards,
    this.isHorizontal = false,
    required this.onCardTap,
  });

  @override
  State<QuickAccessCards> createState() => _QuickAccessCardsState();
}

class _QuickAccessCardsState extends State<QuickAccessCards> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate width for large cards (1/3 of screen minus spacing)
    final gridCardWidth = (screenWidth - 32 - (2 * 10)) / 3;

    return _buildContent(context, gridCardWidth);
  }

  Widget _buildContent(BuildContext context, double gridCardWidth) {
    if (widget.isHorizontal) {
      // SMALL AUTO-SCROLLING CARDS (Horizontal style)
      return _AutoScrollingCards(
        cards: widget.cards.take(6).toList(),
        onCardTap: widget.onCardTap,
        cardWidth: 115,
        cardSpacing: 12,
        autoScroll: true,
      );
    }
    
    // GRID STYLE (Horizontal is false)
    
    // Smart Scrolling: 
    // - If exactly 6 items, keep as 2x3 Grid (user requested)
    // - If exactly 3 items, keep as 1x3 Grid
    // - If > 3 items and != 6, make it a manual horizontal scroll list
    if (widget.cards.length > 3 && widget.cards.length != 6) {
      return _AutoScrollingCards(
        cards: widget.cards,
        onCardTap: widget.onCardTap,
        cardWidth: gridCardWidth,
        cardSpacing: 10,
        autoScroll: false, // User requested manual scroll for this mode
        horizontalPadding: 16,
      );
    }

    // Static Grid (for 1, 2, 3, 6 or any other non-scrolling case)
    return _buildGrid(widget.cards.take(6).toList());
  }

  Widget _buildGrid(List<HomeHeaderCard> displayCards) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: displayCards.length,
        itemBuilder: (context, index) {
          return _QuickAccessCard(
            card: displayCards[index],
            onTap: () => widget.onCardTap(displayCards[index]),
          );
        },
      ),
    );
  }
}

class _AutoScrollingCards extends StatefulWidget {
  final List<HomeHeaderCard> cards;
  final ValueChanged<HomeHeaderCard> onCardTap;
  final double cardWidth;
  final double cardSpacing;
  final bool autoScroll;
  final double horizontalPadding;

  const _AutoScrollingCards({
    required this.cards,
    required this.onCardTap,
    this.cardWidth = 100.0,
    this.cardSpacing = 12.0,
    this.autoScroll = true,
    this.horizontalPadding = 16.0,
  });

  @override
  State<_AutoScrollingCards> createState() => _AutoScrollingCardsState();
}

class _AutoScrollingCardsState extends State<_AutoScrollingCards> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;
  
  static const Duration _autoScrollInterval = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.cards.length <= 3) return; 
    
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (_isUserScrolling || !_scrollController.hasClients) return;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      final newOffset = currentScroll + 0.5;
      
      if (newOffset >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  void _onScrollStart() {
    if (!widget.autoScroll) return;
    _isUserScrolling = true;
  }

  void _onScrollEnd() {
    if (!widget.autoScroll) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isUserScrolling = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: SizedBox(
        height: widget.cardWidth,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              if (notification.dragDetails != null) {
                _onScrollStart();
              }
            } else if (notification is ScrollEndNotification) {
              _onScrollEnd();
            }
            return false;
          },
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            physics: const BouncingScrollPhysics(),
            itemCount: widget.cards.length,
            separatorBuilder: (_, __) => SizedBox(width: widget.cardSpacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: widget.cardWidth,
                height: widget.cardWidth,
                child: _QuickAccessCard(
                  card: widget.cards[index],
                  onTap: () => widget.onCardTap(widget.cards[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final HomeHeaderCard card;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: card.imageUrl != null
          ? LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 115.0;
                final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 115.0;
                return CachedImage(
                  imageUrl: card.imageUrl!,
                  fit: BoxFit.cover,
                  width: w,
                  height: h,
                  errorWidget: _buildPlaceholder(),
                );
              },
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.image,
          color: AppColors.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}
