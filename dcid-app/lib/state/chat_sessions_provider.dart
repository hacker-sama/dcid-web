import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/answer_result.dart';
import 'dart:convert';
import 'providers.dart';

const _uuid = Uuid();

/// Represents a single message in a chat session.
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  String content;
  AnswerResult? result;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    this.result,
  }) : id = id ?? _uuid.v4();

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String?,
    role: json['role'] as String? ?? 'user',
    content: json['content'] as String? ?? '',
    result: json['result'] != null
        ? AnswerResult.fromJson(json['result'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'result': result?.toJson(),
  };
}

/// Represents an entire chat session.
class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;
  DateTime updatedAt;

  ChatSession({
    String? id,
    required this.title,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
  }) : id = id ?? _uuid.v4(),
       messages = messages ?? [],
       updatedAt = updatedAt ?? DateTime.now();

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    messages: (json['messages'] as List<dynamic>? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ActiveChatSessionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setId(String? id) => state = id;
}

/// Global state provider for tracking the currently active chat session.
/// If null, it means we are in the "New Chat" empty state.
final activeChatSessionIdProvider =
    NotifierProvider<ActiveChatSessionNotifier, String?>(
      ActiveChatSessionNotifier.new,
    );

class IsSidebarExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setExpanded(bool expanded) => state = expanded;
}

/// Global state provider for persisting whether the sidebar is expanded or collapsed.
final isSidebarExpandedProvider =
    NotifierProvider<IsSidebarExpandedNotifier, bool>(
      IsSidebarExpandedNotifier.new,
    );

/// Notifier that manages the list of all chat sessions.
class ChatSessionsNotifier extends Notifier<List<ChatSession>> {
  bool _initialized = false;

  @override
  List<ChatSession> build() {
    if (!_initialized) {
      _loadHistory();
      _initialized = true;
    }
    return [];
  }

  Future<void> _loadHistory() async {
    final storage = ref.read(secureStorageProvider);
    final jsonStr = await storage.read(key: 'chat_sessions_v1');
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        state = list
            .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
  }

  Future<void> _saveHistory() async {
    final storage = ref.read(secureStorageProvider);
    final jsonStr = jsonEncode(state.map((s) => s.toJson()).toList());
    await storage.write(key: 'chat_sessions_v1', value: jsonStr);
  }

  /// Creates a new chat session with the given initial user message as the title.
  ChatSession createSession(String initialMessage) {
    // Generate a short title from the initial message
    String title = initialMessage.trim();
    if (title.length > 30) {
      title = '${title.substring(0, 30)}...';
    }

    final session = ChatSession(title: title);
    state = [session, ...state]; // Prepend so newest is first
    _saveHistory();
    return session;
  }

  /// Appends a user message and returns a new empty assistant message to be filled
  /// by the SSE stream.
  ChatMessage addMessage(String sessionId, ChatMessage message) {
    final sessions = [...state];
    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return message;

    final session = sessions[index];
    session.messages.add(message);
    session.updatedAt = DateTime.now();

    // Bubble to top
    sessions.removeAt(index);
    sessions.insert(0, session);
    state = sessions;

    _saveHistory();
    return message;
  }

  /// Replaces or updates a message in the session. This forces a state update.
  void updateMessage(String sessionId, ChatMessage message) {
    final sessions = [...state];
    final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final session = sessions[sessionIndex];
    final msgIndex = session.messages.indexWhere((m) => m.id == message.id);
    if (msgIndex != -1) {
      session.messages[msgIndex] = message;
      // Note: We don't necessarily want to bubble it to top for every token delta,
      // but we do need to trigger a re-render. We'll just assign to state.
      state = sessions;
      _saveHistory();
    }
  }

  void deleteSession(String sessionId) {
    state = state.where((s) => s.id != sessionId).toList();
    _saveHistory();
  }
}

final chatSessionsProvider =
    NotifierProvider<ChatSessionsNotifier, List<ChatSession>>(
      ChatSessionsNotifier.new,
    );
