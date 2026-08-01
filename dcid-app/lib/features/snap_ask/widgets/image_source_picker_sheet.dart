import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Modal bottom sheet for choosing image source (Camera vs Gallery/FilePicker).
void showImageSourcePickerSheet({
  required BuildContext context,
  required VoidCallback onTakePhoto,
  required VoidCallback onPickImage,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thêm ảnh thiết bị',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (!kIsWeb) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: scheme.primaryContainer.withValues(alpha: 0.3),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.camera_alt, color: scheme.primary),
                  ),
                  title: const Text('Chụp ảnh'),
                  subtitle: const Text('Mở camera để chụp thiết bị'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    onTakePhoto();
                  },
                ),
                const SizedBox(height: 8),
              ],
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: scheme.secondaryContainer.withValues(alpha: 0.3),
                leading: CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  child: Icon(Icons.photo_library, color: scheme.secondary),
                ),
                title: Text(kIsWeb ? 'Chọn ảnh từ máy tính' : 'Chọn từ thư viện'),
                subtitle: Text(
                  kIsWeb
                      ? 'Tải lên tệp ảnh từ máy tính'
                      : 'Chọn ảnh có sẵn trên thiết bị',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  onPickImage();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    },
  );
}
