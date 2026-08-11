import 'package:flutter/material.dart';

import '../../../data/models/snap_entry.dart';
import 'thumbnail_strip.dart';

/// Horizontal bar displaying uploaded image thumbnails and image preview options.
class SnapImagePickerBar extends StatelessWidget {
  const SnapImagePickerBar({
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
    return ThumbnailStrip(
      snaps: snaps,
      selectedIndex: selectedIndex,
      scrollController: scrollController,
      formatDate: formatDate,
      onSelect: onSelect,
      onDelete: onDelete,
      onPreview: onPreview,
      scheme: scheme,
    );
  }
}
