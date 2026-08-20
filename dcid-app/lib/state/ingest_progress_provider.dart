import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/ingest_progress_message.dart';
import '../data/stomp_service.dart';
import 'documents_providers.dart';

final stompServiceProvider = Provider<StompService>((ref) {
  final service = StompService();
  ref.onDispose(service.dispose);
  return service;
});

class IngestProgressNotifier extends Notifier<Map<String, IngestProgressMessage>> {
  @override
  Map<String, IngestProgressMessage> build() => {};

  void track(String versionId, {String? initialMessage}) {
    if (versionId.isEmpty) return;

    // Immediately set initial processing state for instant visual feedback on UI
    if (!state.containsKey(versionId)) {
      state = {
        ...state,
        versionId: IngestProgressMessage(
          versionId: versionId,
          step: 'QUEUED',
          progress: 5,
          message: initialMessage ?? 'Processing document pipeline...',
        ),
      };
    }

    final stomp = ref.read(stompServiceProvider);
    stomp.subscribeToIngest(versionId, (msg) {
      state = {...state, versionId: msg};
      if (msg.isDone || msg.isFailed) {
        ref.invalidate(documentsProvider);
      }
    });
  }

  void untrack(String versionId) {
    final stomp = ref.read(stompServiceProvider);
    stomp.unsubscribeFromIngest(versionId);
    final newState = Map<String, IngestProgressMessage>.from(state);
    newState.remove(versionId);
    state = newState;
  }
}

final ingestProgressProvider =
    NotifierProvider<IngestProgressNotifier, Map<String, IngestProgressMessage>>(
  IngestProgressNotifier.new,
);

