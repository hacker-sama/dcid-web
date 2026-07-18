import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

/// Bottom sheet upload PDF (PLAN-FLUTTER-DOCS.md §3.3, §4.3).
/// Pop `true` khi upload thành công.
class UploadDocumentSheet extends ConsumerStatefulWidget {
  const UploadDocumentSheet({super.key});

  @override
  ConsumerState<UploadDocumentSheet> createState() =>
      _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<UploadDocumentSheet> {
  static const _categories = <String, String>{
    'SOP': 'SOP',
    'DRAWING': 'Bản vẽ',
    'CIRCUIT': 'Sơ đồ điện',
    'MAINTENANCE_LOG': 'Nhật ký bảo trì',
    'SAFETY': 'An toàn',
    'OTHER': 'Khác',
  };
  static const _minRoles = <String, String>{
    'OPERATOR': 'Operator',
    'ENGINEER': 'Engineer',
    'QA_ADMIN': 'QA/Admin',
    'ADMIN': 'Admin',
  };

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _machineCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _langController = TextEditingController(text: 'vi,en');

  String? _category;
  String _minRole = 'OPERATOR';
  Uint8List? _fileBytes;
  String? _fileName;
  bool _uploading = false;

  /// After successful upload, show "Processing" state before closing.
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _machineCodeController.dispose();
    _descriptionController.dispose();
    _langController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // withData: true — bắt buộc để có bytes trên web (PlatformFile.path luôn
    // null trong trình duyệt); dùng chung 1 luồng bytes cho mọi nền tảng.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      setState(() => _error = 'Không đọc được nội dung file. Thử lại.');
      return;
    }
    setState(() {
      _fileBytes = file.bytes;
      _fileName = file.name;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fileBytes == null) {
      setState(() => _error = 'Vui lòng chọn file PDF.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref.read(docsRepositoryProvider).uploadDocument(
            title: _titleController.text.trim(),
            category: _category!,
            machineCode: _machineCodeController.text.trim(),
            minRole: _minRole,
            description: _descriptionController.text.trim(),
            lang: _langController.text.trim(),
            fileBytes: _fileBytes!,
            fileName: _fileName ?? 'document.pdf',
          );
      if (mounted) {
        setState(() {
          _uploading = false;
          _processing = true;
        });
        // Show processing state for 3 seconds, then auto-close.
        await Future<void>.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = _friendlyError(e);
        });
      }
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 403) {
        return 'Bạn không có quyền tải tài liệu (cần vai QA/Admin).';
      }
      if (code == 422) {
        final data = e.response?.data;
        if (data is Map && data['errors'] is List) {
          final details = (data['errors'] as List)
              .whereType<Map>()
              .map((err) => '• ${err['field']}: ${err['message']}')
              .join('\n');
          if (details.isNotEmpty) {
            return 'Dữ liệu chưa hợp lệ:\n$details';
          }
        }
        return 'Dữ liệu chưa hợp lệ. Kiểm tra lại các trường.';
      }
    }
    return 'Tải lên thất bại. Kiểm tra kết nối backend.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // ── Processing state ──────────────────────────────────────────────
    if (_processing) {
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 32, 24, 32 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingIndicator(),
            const SizedBox(height: 24),
            Text(
              'Đang xử lý tài liệu...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI đang OCR và phân tích nội dung.\nBạn sẽ được thông báo khi hoàn tất.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }

    // ── Upload form ───────────────────────────────────────────────────
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tải tài liệu mới',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Tiêu đề là bắt buộc'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Loại tài liệu *'),
                items: [
                  for (final entry in _categories.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.value} (${entry.key})'),
                    ),
                ],
                onChanged:
                    _uploading ? null : (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Chọn loại tài liệu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _machineCodeController,
                decoration: const InputDecoration(
                    labelText: 'Mã máy', hintText: 'VD: CNC-01'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _minRole,
                decoration:
                    const InputDecoration(labelText: 'Vai tối thiểu được xem'),
                items: [
                  for (final entry in _minRoles.entries)
                    DropdownMenuItem(
                        value: entry.key, child: Text(entry.value)),
                ],
                onChanged: _uploading
                    ? null
                    : (v) => setState(() => _minRole = v ?? 'OPERATOR'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _langController,
                decoration: const InputDecoration(
                    labelText: 'Ngôn ngữ', hintText: 'vi,en'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _fileName ?? 'Chọn file PDF *',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _uploading ? null : _submit,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_uploading ? 'Đang tải lên...' : 'Tải lên'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed:
                    _uploading ? null : () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated pulsing circle indicator for the "Processing" state.
class _PulsingIndicator extends StatefulWidget {
  const _PulsingIndicator();

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primaryContainer,
        ),
        child: Icon(Icons.auto_awesome, size: 36, color: scheme.primary),
      ),
    );
  }
}
