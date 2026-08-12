import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../state/suggestions_provider.dart';

/// Hero welcome header and dynamic suggestion chips shown when chat is empty.
class SearchEmptyState extends ConsumerStatefulWidget {
  const SearchEmptyState({
    super.key,
    required this.onUseSuggestion,
  });

  final ValueChanged<String> onUseSuggestion;

  @override
  ConsumerState<SearchEmptyState> createState() => _SearchEmptyStateState();
}

class _SearchEmptyStateState extends ConsumerState<SearchEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final accent = accentFor(context);
    final suggestions = ref.watch(searchSuggestionsProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing AI icon with radial glow isolated by RepaintBoundary
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  final scaleFactor = 0.96 + (_pulseAnim.value * 0.08);
                  final angle = math.sin(_pulseController.value * math.pi) * 0.04;
                  return Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: scaleFactor,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? kDarkCard : Colors.white,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.2),
                        // Reduced from 20 to 12 — cheaper GPU paint, still glows
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.precision_manufacturing_rounded,
                      size: 36,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Static content isolated in its own repaint boundary so it is
            // not repainted each frame by the icon pulse animation above.
            RepaintBoundary(
              child: Column(
                children: [
                  // Bold title
                  Text(
                    'Smart KCN Docs',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'AI-powered industrial knowledge assistant',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),

                  const SizedBox(height: 36),

                  // Dynamic suggestion chips
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: suggestions.map((item) {
                      return SearchSuggestionChip(
                        icon: item.icon,
                        label: item.label,
                        onTap: () => widget.onUseSuggestion(item.label),
                        accent: accent,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchSuggestionChip extends StatefulWidget {
  const SearchSuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.accent,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final Color accent;
  final IconData? icon;

  @override
  State<SearchSuggestionChip> createState() => _SearchSuggestionChipState();
}

class _SearchSuggestionChipState extends State<SearchSuggestionChip> {
  bool _hovered = false;
  bool _pressed = false;

  double get _scale => _pressed ? 0.96 : (_hovered ? 1.04 : 1.0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: _hovered
                      ? widget.accent.withValues(alpha: 0.75)
                      : colorScheme.outlineVariant.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                color: _hovered
                    ? widget.accent.withValues(alpha: isDark ? 0.1 : 0.06)
                    : Colors.transparent,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 64,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 14,
                        color: _hovered
                            ? widget.accent
                            : colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _hovered
                              ? widget.accent
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
