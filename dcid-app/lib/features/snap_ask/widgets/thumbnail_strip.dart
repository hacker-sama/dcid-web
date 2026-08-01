import 'package:flutter/material.dart';

import '../../../data/models/snap_entry.dart';

/// Horizontal strip displaying thumbnails of captured / uploaded images.
class ThumbnailStrip extends StatelessWidget {
  const ThumbnailStrip({
    super.key,
    required this.snaps,
    required this.selectedIndex,
    required this.scrollController,
    required this.formatDate,
    required this.onSelect,
    required this.onDelete,
    required this.onPreview,
    required this.scheme,
  });

  final List<SnapEntry> snaps;
  final int? selectedIndex;
  final ScrollController scrollController;
  final String Function(DateTime) formatDate;
  final void Function(int) onSelect;
  final void Function(int) onDelete;
  final void Function(int) onPreview;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: snaps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final snap = snaps[index];
          final isSelected = selectedIndex == index;
          return ThumbnailCard(
            snap: snap,
            index: index,
            isSelected: isSelected,
            formatDate: formatDate,
            onTap: () => onSelect(index),
            onDelete: () => onDelete(index),
            onPreview: () => onPreview(index),
            scheme: scheme,
          );
        },
      ),
    );
  }
}

/// Individual Card item for an image in the [ThumbnailStrip].
class ThumbnailCard extends StatelessWidget {
  const ThumbnailCard({
    super.key,
    required this.snap,
    required this.index,
    required this.isSelected,
    required this.formatDate,
    required this.onTap,
    required this.onDelete,
    required this.onPreview,
    required this.scheme,
  });

  final SnapEntry snap;
  final int index;
  final bool isSelected;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPreview;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final chatCount = snap.messages.length;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image fill
              Image.memory(
                snap.bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: scheme.surfaceContainerHigh,
                  child: Icon(Icons.broken_image, color: scheme.outlineVariant),
                ),
              ),

              // Gradient overlay at bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),

              // Timestamp bottom-left
              Positioned(
                left: 5,
                bottom: 5,
                right: 22,
                child: Text(
                  formatDate(snap.capturedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Chat count badge (top-left)
              if (chatCount > 0)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$chatCount',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Active checkmark (top-right)
              if (isSelected)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 11, color: scheme.onPrimary),
                  ),
                ),

              // Delete button (bottom-right, overlaid)
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
