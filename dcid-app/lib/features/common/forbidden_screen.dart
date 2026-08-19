import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';

class ForbiddenScreen extends ConsumerWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.forbiddenTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 64),
            const SizedBox(height: 12),
            Text(strings.forbiddenDesc),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/search'),
              child: Text(strings.backToSearch),
            ),
          ],
        ),
      ),
    );
  }
}
