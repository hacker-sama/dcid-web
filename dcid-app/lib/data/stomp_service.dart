import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../core/env.dart';
import 'models/ingest_progress_message.dart';

class StompService {
  StompClient? _client;
  final Map<String, StompUnsubscribe> _subscriptions = {};

  void init() {
    if (_client != null) return;
    _client = StompClient(
      config: StompConfig(
        url: Env.wsBaseUrl,
        onConnect: (frame) {
          debugPrint('STOMP Connected to WebSocket');
        },
        onWebSocketError: (error) {
          debugPrint('STOMP WebSocket Error: $error');
        },
        onStompError: (frame) {
          debugPrint('STOMP Error: ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('STOMP Disconnected');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client?.activate();
  }

  void subscribeToIngest(String versionId, void Function(IngestProgressMessage) onProgress) {
    init();
    final topic = '/topic/ingest/$versionId';
    if (_subscriptions.containsKey(topic)) return;

    final unsubscribe = _client?.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            final msg = IngestProgressMessage.fromJson(data);
            onProgress(msg);
          } catch (e) {
            debugPrint('Failed to parse STOMP message: $e');
          }
        }
      },
    );
    if (unsubscribe != null) {
      _subscriptions[topic] = unsubscribe;
    }
  }

  void unsubscribeFromIngest(String versionId) {
    final topic = '/topic/ingest/$versionId';
    final unsub = _subscriptions.remove(topic);
    unsub?.call();
  }

  void dispose() {
    _subscriptions.clear();
    _client?.deactivate();
    _client = null;
  }
}
