import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('403')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 64),
            const SizedBox(height: 12),
            const Text('Bạn không có quyền truy cập mục này.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/search'),
              child: const Text('Về trang tra cứu'),
            ),
          ],
        ),
      ),
    );
  }
}
