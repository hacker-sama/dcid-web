import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/answer_result.dart';
import '../data/models/guest_session_models.dart';
import 'providers.dart';

class ChatMessageItem {
  ChatMessageItem({
    required this.isUser,
    required this.text,
    this.answerResult,
    required this.timestamp,
  });

  final bool isUser;
  final String text;
  final AnswerResult? answerResult;
  final DateTime timestamp;
}

class GuestSessionState {
  const GuestSessionState({
    this.session,
    this.sessionToken,
    this.documents = const [],
    this.messages = const [],
    this.isLoading = false,
    this.isAsking = false,
    this.isUploading = false,
    this.error,
  });

  final GuestSessionData? session;
  final String? sessionToken;
  final List<GuestDocumentItem> documents;
  final List<ChatMessageItem> messages;
  final bool isLoading;
  final bool isAsking;
  final bool isUploading;
  final String? error;

  bool get hasActiveSession => session != null && sessionToken != null;
  bool get hasReadyDocuments => documents.any((d) => d.isReady);

  GuestSessionState copyWith({
    GuestSessionData? session,
    String? sessionToken,
    List<GuestDocumentItem>? documents,
    List<ChatMessageItem>? messages,
    bool? isLoading,
    bool? isAsking,
    bool? isUploading,
    String? error,
  }) {
    return GuestSessionState(
      session: session ?? this.session,
      sessionToken: sessionToken ?? this.sessionToken,
      documents: documents ?? this.documents,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isAsking: isAsking ?? this.isAsking,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

class GuestSessionController extends Notifier<GuestSessionState> {
  Timer? _pollingTimer;

  @override
  GuestSessionState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    return const GuestSessionState();
  }

  /// Khởi tạo một phiên hỏi đáp tạm thời mới.
  Future<void> initSession() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(guestRepositoryProvider);
      final createRes = await repo.createSession();
      final detail = await repo.getSessionDetail(createRes.sessionId, createRes.sessionToken);

      state = state.copyWith(
        session: detail,
        sessionToken: createRes.sessionToken,
        documents: detail.documents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tạo phiên làm việc mới: ${e.toString()}',
      );
    }
  }

  /// Upload file PDF tạm vào phiên.
  Future<void> uploadDocument(Uint8List bytes, String filename) async {
    if (!state.hasActiveSession) {
      await initSession();
    }
    if (!state.hasActiveSession) return;

    state = state.copyWith(isUploading: true, error: null);
    try {
      final repo = ref.read(guestRepositoryProvider);
      final uploadedDoc = await repo.uploadDocument(
        state.session!.id,
        state.sessionToken!,
        bytes,
        filename,
      );

      final updatedDocs = [...state.documents, uploadedDoc];
      state = state.copyWith(
        documents: updatedDocs,
        isUploading: false,
      );

      // Kích hoạt polling kiểm tra trạng thái xử lý OCR/Indexing
      _startStatusPolling(uploadedDoc.id);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Lỗi khi tải file: ${e.toString()}',
      );
    }
  }

  /// Gửi câu hỏi cho AI trong phạm vi phiên tạm.
  Future<void> askQuestion(String question) async {
    if (question.trim().isEmpty || !state.hasActiveSession || state.isAsking) return;

    final userMsg = ChatMessageItem(
      isUser: true,
      text: question.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isAsking: true,
      error: null,
    );

    try {
      final repo = ref.read(guestRepositoryProvider);
      final answer = await repo.askQuestion(
        state.session!.id,
        state.sessionToken!,
        question.trim(),
      );

      final aiMsg = ChatMessageItem(
        isUser: false,
        text: answer.answer,
        answerResult: answer,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isAsking: false,
      );
    } catch (e) {
      final errorMsg = ChatMessageItem(
        isUser: false,
        text: 'Lỗi xử lý câu hỏi: ${e.toString()}',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isAsking: false,
      );
    }
  }

  /// Khách chủ động hủy phiên.
  Future<void> endSession() async {
    if (!state.hasActiveSession) return;
    _pollingTimer?.cancel();

    try {
      final repo = ref.read(guestRepositoryProvider);
      await repo.deleteSession(state.session!.id, state.sessionToken!);
    } catch (_) {}

    state = const GuestSessionState();
  }

  void _startStatusPolling(String docId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!state.hasActiveSession) {
        timer.cancel();
        return;
      }

      try {
        final repo = ref.read(guestRepositoryProvider);
        final statusDoc = await repo.getDocumentStatus(
          state.session!.id,
          docId,
          state.sessionToken!,
        );

        final updatedDocs = state.documents.map((d) {
          return d.id == docId ? statusDoc : d;
        }).toList();

        state = state.copyWith(documents: updatedDocs);

        if (statusDoc.isReady || statusDoc.isFailed) {
          timer.cancel();
        }
      } catch (_) {
        timer.cancel();
      }
    });
  }
}

final guestSessionControllerProvider =
    NotifierProvider<GuestSessionController, GuestSessionState>(
  GuestSessionController.new,
);
