import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../router/routes.dart';
import 'animated_search_text.dart';

class GlobalSearchBar extends StatelessWidget {
  final bool hasBackground;
  final bool showAiButton;
  final EdgeInsetsGeometry? padding;

  const GlobalSearchBar({
    super.key,
    this.hasBackground = false,
    this.showAiButton = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(Routes.search),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    const Expanded(child: AnimatedSearchText()),
                  ],
                ),
              ),
            ),
          ),
          if (showAiButton) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push(Routes.aiChat),
              child: Image.asset(
                'assets/icons/aibutton.gif',
                height: 48,
                width: 48,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
