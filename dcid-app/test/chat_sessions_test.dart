import 'package:dcid_app/state/chat_sessions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('ChatSessionsNotifier', () {
    test('creates a new session and sets title from message', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatSessionsProvider.notifier);
      final initialMessage = 'How do I operate the CNC machine safely?';
      
      final session = notifier.createSession(initialMessage);
      
      final sessions = container.read(chatSessionsProvider);
      
      expect(sessions.length, 1);
      expect(sessions.first.id, session.id);
      expect(sessions.first.title, 'How do I operate the CNC machi...');
      expect(sessions.first.messages, isEmpty);
    });

    test('adds messages to existing session and bubbles to top', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatSessionsProvider.notifier);
      
      final session1 = notifier.createSession('First chat');
      final session2 = notifier.createSession('Second chat');
      
      // Initially session2 is at top because it was created most recently
      var sessions = container.read(chatSessionsProvider);
      expect(sessions.first.id, session2.id);

      // Add a message to session1
      final msg = ChatMessage(role: 'user', content: 'Hello');
      notifier.addMessage(session1.id, msg);
      
      // session1 should now be at the top
      sessions = container.read(chatSessionsProvider);
      expect(sessions.first.id, session1.id);
      expect(sessions.first.messages.length, 1);
      expect(sessions.first.messages.first.content, 'Hello');
    });

    test('updates message in session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatSessionsProvider.notifier);
      
      final session = notifier.createSession('Test chat');
      final msg = ChatMessage(role: 'assistant', content: 'Init');
      notifier.addMessage(session.id, msg);
      
      msg.content = 'Init update';
      notifier.updateMessage(session.id, msg);
      
      final sessions = container.read(chatSessionsProvider);
      expect(sessions.first.messages.first.content, 'Init update');
    });
  });

  group('ActiveChatSessionNotifier', () {
    test('sets active session id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeChatSessionIdProvider.notifier);
      expect(container.read(activeChatSessionIdProvider), isNull);

      notifier.setId('session-123');
      expect(container.read(activeChatSessionIdProvider), 'session-123');
      
      notifier.setId(null);
      expect(container.read(activeChatSessionIdProvider), isNull);
    });
  });

  group('IsSidebarExpandedNotifier', () {
    test('toggles sidebar state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(isSidebarExpandedProvider.notifier);
      expect(container.read(isSidebarExpandedProvider), isFalse);

      notifier.toggle();
      expect(container.read(isSidebarExpandedProvider), isTrue);
      
      notifier.toggle();
      expect(container.read(isSidebarExpandedProvider), isFalse);
    });
  });
}
