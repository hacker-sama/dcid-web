import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Form component for uploading a new technical document.
class UploadDocumentForm extends StatelessWidget {
  const UploadDocumentForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.machineCodeController,
    required this.descriptionController,
    required this.langController,
    required this.category,
    required this.minRole,
    required this.fileBytes,
    required this.fileName,
    required this.uploading,
    required this.error,
    required this.categories,
    required this.minRoles,
    required this.onCategoryChanged,
    required this.onMinRoleChanged,
    required this.onPickFile,
    required this.onSubmit,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController machineCodeController;
  final TextEditingController descriptionController;
  final TextEditingController langController;

  final String? category;
  final String minRole;
  final Uint8List? fileBytes;
  final String? fileName;
  final bool uploading;
  final String? error;

  final Map<String, String> categories;
  final Map<String, String> minRoles;

  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onMinRoleChanged;
  final VoidCallback onPickFile;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final accent = accentFor(context);

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modal Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload New Document',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add SOPs, drawings, manuals or specs to DCID',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: uploading ? null : onCancel,
                tooltip: 'Cancel',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 1. Document Title (Full width)
          TextFormField(
            controller: titleController,
            enabled: !uploading,
            decoration: const InputDecoration(
              labelText: 'Document Title *',
              hintText: 'e.g. CNC-01 Maintenance & Calibration SOP',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Document Title is required'
                : null,
          ),

          const SizedBox(height: 14),

          // 2. Row: Category & Machine Code (2-column layout with Expanded)
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 450;
              final catField = DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: [
                  for (final entry in categories.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        '${entry.value} (${entry.key})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: uploading ? null : onCategoryChanged,
                validator: (v) => v == null ? 'Select category' : null,
              );

              final codeField = TextFormField(
                controller: machineCodeController,
                enabled: !uploading,
                decoration: const InputDecoration(
                  labelText: 'Machine Code',
                  hintText: 'e.g. CNC-01',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              );

              if (isCompact) {
                return Column(
                  children: [
                    catField,
                    const SizedBox(height: 14),
                    codeField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: catField),
                  const SizedBox(width: 12),
                  Expanded(child: codeField),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // 3. Row: Min Required Role & Languages (2-column layout with Expanded)
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 450;
              final roleField = DropdownButtonFormField<String>(
                initialValue: minRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Min Required Role',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: [
                  for (final entry in minRoles.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: uploading ? null : onMinRoleChanged,
              );

              final langField = TextFormField(
                controller: langController,
                enabled: !uploading,
                decoration: const InputDecoration(
                  labelText: 'Languages (e.g. en, vi)',
                  hintText: 'vi,en',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              );

              if (isCompact) {
                return Column(
                  children: [
                    roleField,
                    const SizedBox(height: 14),
                    langField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: roleField),
                  const SizedBox(width: 12),
                  Expanded(child: langField),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // 4. Description (Full width)
          TextFormField(
            controller: descriptionController,
            enabled: !uploading,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Brief summary of scope, revision or safety warnings...',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 16),

          // 5. Drag & Drop File Zone
          DragDropFileZone(
            fileBytes: fileBytes,
            fileName: fileName,
            uploading: uploading,
            formatFileSize: _formatFileSize,
            onPickFile: onPickFile,
            accent: accent,
            scheme: scheme,
            isDark: isDark,
          ),

          // Error alert
          if (error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 18, color: scheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onErrorContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: uploading ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: uploading ? null : onSubmit,
                icon: uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(uploading ? 'Uploading...' : 'Upload'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Intuitive Drag & Drop file drop zone with selected file preview.
class DragDropFileZone extends StatefulWidget {
  const DragDropFileZone({
    super.key,
    required this.fileBytes,
    required this.fileName,
    required this.uploading,
    required this.formatFileSize,
    required this.onPickFile,
    required this.accent,
    required this.scheme,
    required this.isDark,
  });

  final Uint8List? fileBytes;
  final String? fileName;
  final bool uploading;
  final String Function(int) formatFileSize;
  final VoidCallback onPickFile;
  final Color accent;
  final ColorScheme scheme;
  final bool isDark;

  @override
  State<DragDropFileZone> createState() => _DragDropFileZoneState();
}

class _DragDropFileZoneState extends State<DragDropFileZone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.fileBytes != null && widget.fileName != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.uploading ? null : widget.onPickFile,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: hasFile
                ? widget.accent.withValues(alpha: widget.isDark ? 0.12 : 0.05)
                : (_hovered
                    ? widget.accent
                        .withValues(alpha: widget.isDark ? 0.08 : 0.04)
                    : (widget.isDark
                        ? kDarkCard
                        : widget.scheme.surfaceContainerLowest)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasFile
                  ? widget.accent.withValues(alpha: 0.8)
                  : (_hovered
                      ? widget.accent
                      : widget.scheme.outlineVariant.withValues(alpha: 0.6)),
              width: hasFile || _hovered ? 1.8 : 1.2,
            ),
          ),
          child: hasFile
              ? Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: widget.accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.formatFileSize(
                                widget.fileBytes!.lengthInBytes),
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: widget.uploading ? null : widget.onPickFile,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Change', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: widget.accent.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 26,
                        color: _hovered
                            ? widget.accent
                            : widget.scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.scheme.onSurface,
                        ),
                        children: [
                          const TextSpan(text: 'Drag & drop PDF here or '),
                          TextSpan(
                            text: 'browse',
                            style: TextStyle(
                              color: widget.accent,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supports PDF documents up to 50MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
