import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constrained_content.dart';
import '../../data/models/answer_result.dart';
import '../../state/providers.dart';
import '../search/answer_view.dart';

class SnapAskScreen extends ConsumerStatefulWidget {
  const SnapAskScreen({super.key});

  @override
  ConsumerState<SnapAskScreen> createState() => _SnapAskScreenState();
}

class _SnapAskScreenState extends ConsumerState<SnapAskScreen> {
  final _questionController = TextEditingController();
  Uint8List? _imageBytes;
  String? _fileName;
  bool _loading = false;
  AnswerResult? _result;
  String? _error;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    
    final file = result.files.first;
    if (file.bytes == null) {
      setState(() => _error = 'Không thể đọc dữ liệu ảnh.');
      return;
    }

    setState(() {
      _imageBytes = file.bytes;
      _fileName = file.name;
      _error = null;
      _result = null; // Clear old result when new image is picked
    });
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _fileName = null;
      _result = null;
    });
  }

  Future<void> _submit() async {
    if (_imageBytes == null) {
      setState(() => _error = 'Vui lòng chọn hoặc chụp một bức ảnh.');
      return;
    }

    final question = _questionController.text.trim();
    
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final repo = ref.read(docsRepositoryProvider);
      final result = await repo.askWithImage(
        question.isEmpty ? 'Đây là bộ phận/tài liệu gì?' : question, 
        _imageBytes!, 
        _fileName ?? 'image.jpg'
      );
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không truy vấn được. Kiểm tra kết nối.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedContent(
      maxWidth: 840,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image Picker Area ───────────────────────────────────────
            if (_imageBytes == null)
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Chụp hoặc chọn ảnh thiết bị',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                      image: DecorationImage(
                        image: MemoryImage(_imageBytes!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton.filled(
                      onPressed: _clearImage,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.surface.withValues(alpha: 0.8),
                        foregroundColor: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              
            const SizedBox(height: 16),

            // ── Question Input Area ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi (tùy chọn)...',
                      prefixIcon: Icon(Icons.help_outline),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: const Text('Hỏi AI'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
              
            // ── Result Area ──────────────────────────────────────────────
            if (_result != null)
              Expanded(
                child: AnswerView(result: _result!),
              ),
          ],
        ),
      ),
    );
  }
}
