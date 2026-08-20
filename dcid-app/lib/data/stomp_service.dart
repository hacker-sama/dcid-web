import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../core/env.dart';
import 'models/ingest_progress_message.dart';

class StompService {
  StompClient? _client;
  bool _isConnected = false;
  final Map<String, void Function(IngestProgressMessage)> _listeners = {};
  final Map<String, StompUnsubscribe> _activeSubscriptions = {};

  bool get isConnected => _isConnected;

  void init() {
    if (_client != null) return;
    _client = StompClient(
      config: StompConfig(
        url: Env.wsBaseUrl,
        onConnect: (frame) {
          debugPrint('STOMP: Connected to WebSocket (${Env.wsBaseUrl})');
          _isConnected = true;
          _resubscribeAll();
        },
        onWebSocketError: (error) {
          debugPrint('STOMP WebSocket Error: $error');
          _isConnected = false;
        },
        onStompError: (frame) {
          debugPrint('STOMP Error: ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('STOMP: Disconnected');
          _isConnected = false;
          _activeSubscriptions.clear();
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    try {
      _client?.activate();
    } catch (e) {
      debugPrint('STOMP activate error: $e');
    }
  }

  void _resubscribeAll() {
    for (final entry in _listeners.entries) {
      final topic = entry.key;
      final callback = entry.value;
      if (!_activeSubscriptions.containsKey(topic)) {
        _doSubscribe(topic, callback);
      }
    }
  }

  void _doSubscribe(String topic, void Function(IngestProgressMessage) onProgress) {
    if (_client == null || !_isConnected) return;
    try {
      final unsub = _client?.subscribe(
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
      if (unsub != null) {
        _activeSubscriptions[topic] = unsub;
      }
    } catch (e) {
      debugPrint('STOMP subscribe warning ($topic): $e');
    }
  }

  void subscribeToIngest(String versionId, void Function(IngestProgressMessage) onProgress) {
    final topic = '/topic/ingest/$versionId';
    _listeners[topic] = onProgress;
    init();
    if (_isConnected && !_activeSubscriptions.containsKey(topic)) {
      _doSubscribe(topic, onProgress);
    }
  }

  void unsubscribeFromIngest(String versionId) {
    final topic = '/topic/ingest/$versionId';
    _listeners.remove(topic);
    final unsub = _activeSubscriptions.remove(topic);
    try {
      unsub?.call();
    } catch (_) {}
  }

  void dispose() {
    _listeners.clear();
    for (final unsub in _activeSubscriptions.values) {
      try {
        unsub();
      } catch (_) {}
    }
    _activeSubscriptions.clear();
    try {
      _client?.deactivate();
    } catch (_) {}
    _client = null;
    _isConnected = false;
  }
}

