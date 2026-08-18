import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/ingest_progress_provider.dart';
import '../../state/providers.dart';
import 'widgets/upload_document_form.dart';

/// Modal bottom sheet / dialog for uploading PDF documents.
/// Returns the new document ID (String) upon successful upload.
class UploadDocumentSheet extends ConsumerStatefulWidget {
  const UploadDocumentSheet({super.key});

  @override
  ConsumerState<UploadDocumentSheet> createState() =>
      _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<UploadDocumentSheet> {
  static const _categories = <String, String>{
    'SOP': 'SOP',
    'DRAWING': 'Drawing',
    'CIRCUIT': 'Circuit Diagram',
    'MAINTENANCE_LOG': 'Maintenance Log',
    'SAFETY': 'Safety Rules',
    'OTHER': 'Other',
  };

  static const _minRoles = <String, String>{
    'OPERATOR': 'Operator',
    'ENGINEER': 'Engineer',
    'QA_ADMIN': 'QA / Admin',
    'ADMIN': 'Admin',
  };

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _machineCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _langController = TextEditingController(text: 'en,vi');

  String? _category;
  String _minRole = 'OPERATOR';
  Uint8List? _fileBytes;
  String? _fileName;
  bool _uploading = false;
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      setState(
          () => _error = 'Could not read file contents. Please try again.');
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
      setState(() => _error = 'Please select a PDF file before uploading.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final detail = await ref.read(docsRepositoryProvider).uploadDocument(
            title: _titleController.text.trim(),
            category: _category!,
            machineCode: _machineCodeController.text.trim(),
            minRole: _minRole,
            description: _descriptionController.text.trim(),
            lang: _langController.text.trim(),
            fileBytes: _fileBytes!,
            fileName: _fileName ?? 'document.pdf',
          );
      try {
        if (detail.versions.isNotEmpty) {
          ref.read(ingestProgressProvider.notifier).track(detail.versions.first.id);
        }
      } catch (stompError) {
        debugPrint('STOMP progress tracking init warning: $stompError');
      }
      if (mounted) Navigator.of(context).pop(detail.document.id);
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
        return 'You do not have permission to upload documents (requires QA/Admin role).';
      }
      if (code == 422) {
        final data = e.response?.data;
        if (data is Map && data['errors'] is List) {
          final details = (data['errors'] as List)
              .whereType<Map>()
              .map((err) => '• ${err['field']}: ${err['message']}')
              .join('\n');
          if (details.isNotEmpty) {
            return 'Invalid parameters:\n$details';
          }
        }
        return 'Invalid input parameters. Please check required fields.';
      }
    }
    return 'Upload failed. Please check backend connection.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: UploadDocumentForm(
          formKey: _formKey,
          titleController: _titleController,
          machineCodeController: _machineCodeController,
          descriptionController: _descriptionController,
          langController: _langController,
          category: _category,
          minRole: _minRole,
          fileBytes: _fileBytes,
          fileName: _fileName,
          uploading: _uploading,
          error: _error,
          categories: _categories,
          minRoles: _minRoles,
          onCategoryChanged: (v) => setState(() => _category = v),
          onMinRoleChanged: (v) => setState(() => _minRole = v ?? 'OPERATOR'),
          onPickFile: _pickFile,
          onSubmit: _submit,
          onCancel: () => Navigator.of(context).pop(null),
        ),
      ),
    );
  }
}
