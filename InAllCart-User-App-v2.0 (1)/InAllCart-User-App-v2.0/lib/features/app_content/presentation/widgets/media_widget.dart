import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/media_cards/full_width_media_card.dart';
import '../../../../core/widgets/media_cards/padded_media_card.dart';
import '../../../../core/widgets/media_cards/rounded_media_card.dart';
import '../../domain/entities/app_content.dart';

class MediaContentWidget extends StatefulWidget {
  final AppContent content;
  final VoidCallback? onTap;
  final Function(ContentLinkType type, int? id, String? url)? onLinkTap;

  const MediaContentWidget({
    super.key,
    required this.content,
    this.onTap,
    this.onLinkTap,
  });

  @override
  State<MediaContentWidget> createState() => _MediaContentWidgetState();
}

class _MediaContentWidgetState extends State<MediaContentWidget> {
  Color? _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return null;
    try {
      final hex = colorStr.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      // Invalid colour string — fall through to null and use the default.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final media = content.media;
    final mediaItems = content.mediaItems;
    
    // Build title and subtitle
    Widget? headerWidget;
    if (content.showTitle && content.title != null ||
        content.showSubtitle && content.subtitle != null) {
      headerWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (content.showTitle && content.title != null) ...[
              Text(
                content.title!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
            if (content.showSubtitle && content.subtitle != null) ...[
              Text(
                content.subtitle!,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
            ] else if (content.showTitle && content.title != null) ...[
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }

    // Prepare background
    MediaCardBackground? background;
    if (content.background?.enabled == true) {
      switch (content.background!.type) {
        case BackgroundType.color:
          background = MediaCardBackground(
            type: MediaBackgroundType.color,
            color: _parseColor(content.background!.color) ?? AppColors.surfaceLight,
          );
          break;
        case BackgroundType.image:
        case BackgroundType.gif:
          if (content.background!.mediaUrl != null) {
            background = MediaCardBackground(
              type: content.background!.type == BackgroundType.image 
                  ? MediaBackgroundType.image 
                  : MediaBackgroundType.gif,
              mediaUrl: content.background!.mediaUrl,
            );
          }
          break;
        case BackgroundType.video:
          if (content.background!.mediaUrl != null) {
            background = MediaCardBackground(
              type: MediaBackgroundType.video,
              mediaUrl: content.background!.mediaUrl,
            );
          }
          break;
        default:
          break;
      }
    }

    // Build media card
    Widget mediaCard;
    
    // Multi-item mode
    if (mediaItems != null && mediaItems.isNotEmpty) {
      final items = mediaItems.map((item) {
        return MediaCardItem(
          imageUrl: item.type != 'video' ? item.url : null,
          videoUrl: item.type == 'video' ? item.url : null,
          type: item.type,
          onTap: item.linkType != ContentLinkType.none
              ? () => _handleItemTap(item)
              : null,
        );
      }).toList();

      // Backend does not send enableHorizontalAnimation for Media widgets.
      // Rule 1: Full Width (style1) naturally becomes a slider if items >= 2.
      // Rule 2: Padded (style2) and Rounded (style3) act strictly as Grids based on Rows/Columns.
      final enableAutoSlider = content.style == ContentStyle.style1 && items.length >= 2;

      mediaCard = _buildMediaCard(
        items: items,
        gridColumns: content.gridColumns,
        gridRows: content.gridRows,
        height: media?.height.toDouble(),
        width: media?.width?.toDouble(),
        enableAutoSlider: enableAutoSlider,
        background: background,
      );
    }
    // Single media mode (legacy)
    else if (media != null && media.url != null) {
      final isClickable = content.link?.type != ContentLinkType.none;
      
      mediaCard = _buildMediaCard(
        imageUrl: media.type != 'video' ? media.url : null,
        videoUrl: media.type == 'video' ? media.url : null,
        mediaType: media.type,
        height: media.height.toDouble(),
        width: media.width?.toDouble(),
        onTap: isClickable ? widget.onTap : null,
        background: background,
      );
    }
    // No media
    else {
      return const SizedBox.shrink();
    }

    // Combine header and media
    if (headerWidget != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          headerWidget,
          mediaCard,
        ],
      );
    }

    return mediaCard;
  }

  Widget _buildMediaCard({
    // Single media
    String? imageUrl,
    String? videoUrl,
    String? mediaType,
    double? height,
    double? width,
    VoidCallback? onTap,
    // Multi-item
    List<MediaCardItem>? items,
    int? gridColumns,
    int? gridRows,
    bool enableAutoSlider = false,
    // Background
    MediaCardBackground? background,
  }) {
    switch (widget.content.style) {
      case ContentStyle.style1: // Full width
        return FullWidthMediaCard(
          key: ValueKey('media_style_${widget.content.style.name}'),
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          mediaType: mediaType,
          height: height,
          width: width,
          onTap: onTap,
          items: items,
          gridColumns: gridColumns,
          gridRows: gridRows,
          enableAutoSlider: enableAutoSlider,
          background: background,
        );
        
      case ContentStyle.style2: // Padded
        return PaddedMediaCard(
          key: ValueKey('media_style_${widget.content.style.name}'),
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          mediaType: mediaType,
          height: height,
          width: width,
          onTap: onTap,
          items: items,
          gridColumns: gridColumns,
          gridRows: gridRows,
          enableAutoSlider: enableAutoSlider,
          background: background,
        );
        
      case ContentStyle.style3: // Rounded
        return RoundedMediaCard(
          key: ValueKey('media_style_${widget.content.style.name}'),
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          mediaType: mediaType,
          height: height,
          width: width,
          onTap: onTap,
          items: items,
          gridColumns: gridColumns,
          gridRows: gridRows,
          enableAutoSlider: enableAutoSlider,
          background: background,
        );
        
      case ContentStyle.style4:
        // Style 4 not applicable for media, fallback to full width
        return FullWidthMediaCard(
          key: ValueKey('media_style_fallback_${widget.content.style.name}'),
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          mediaType: mediaType,
          height: height,
          width: width,
          onTap: onTap,
          items: items,
          gridColumns: gridColumns,
          gridRows: gridRows,
          enableAutoSlider: enableAutoSlider,
          background: background,
        );
    }
  }

  void _handleItemTap(MediaItem item) {
    if (widget.onLinkTap != null) {
      widget.onLinkTap!(item.linkType, item.linkId, item.linkUrl);
    }
  }
}
