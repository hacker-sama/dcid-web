import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';

/// Hero welcome header and suggestion chips shown when chat is empty.
class SearchEmptyState extends StatefulWidget {
  const SearchEmptyState({
    super.key,
    required this.onUseSuggestion,
  });

  final ValueChanged<String> onUseSuggestion;

  @override
  State<SearchEmptyState> createState() => _SearchEmptyStateState();
}

class _SearchEmptyStateState extends State<SearchEmptyState>
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing AI icon with radial glow
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Transform.rotate(
                angle: math.sin(_pulseController.value * math.pi) * 0.05,
                child: Opacity(
                  opacity: 0.7 + (_pulseAnim.value * 0.3),
                  child: child,
                ),
              ),
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
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
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

            const SizedBox(height: 24),

            // Bold title
            Text(
              'Smart KCN Docs',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'AI-powered industrial knowledge assistant',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 36),

            // Suggestion chips
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                SearchSuggestionChip(
                  icon: Icons.build_circle_outlined,
                  label: 'Check CNC-01 maintenance steps',
                  onTap: () =>
                      widget.onUseSuggestion('Check CNC-01 maintenance steps'),
                  accent: accent,
                ),
                SearchSuggestionChip(
                  icon: Icons.shield_outlined,
                  label: 'Summarize assembly safety rules',
                  onTap: () => widget
                      .onUseSuggestion('Summarize assembly safety rules'),
                  accent: accent,
                ),
                SearchSuggestionChip(
                  icon: Icons.bolt_outlined,
                  label: 'Find voltage specs for TRUC-1',
                  onTap: () =>
                      widget.onUseSuggestion('Find voltage specs for TRUC-1'),
                  accent: accent,
                ),
                SearchSuggestionChip(
                  icon: Icons.schema_outlined,
                  label: 'List all drawings for Module A',
                  onTap: () =>
                      widget.onUseSuggestion('List all drawings for Module A'),
                  accent: accent,
                ),
              ],
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

    return MouseRegion(
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
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _hovered
                        ? widget.accent
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
