import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/ingest_progress_message.dart';
import '../data/stomp_service.dart';

final stompServiceProvider = Provider<StompService>((ref) {
  final service = StompService();
  ref.onDispose(service.dispose);
  return service;
});

class IngestProgressNotifier extends Notifier<Map<String, IngestProgressMessage>> {
  @override
  Map<String, IngestProgressMessage> build() => {};

  void track(String versionId) {
    if (versionId.isEmpty) return;
    final stomp = ref.read(stompServiceProvider);
    stomp.subscribeToIngest(versionId, (msg) {
      state = {...state, versionId: msg};
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
