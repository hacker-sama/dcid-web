import 'dart:typed_data';

import 'package:flutter/rendering.dart' show Rect;

import 'answer_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatMessage — one Q&A exchange stored per image
// ─────────────────────────────────────────────────────────────────────────────

class ChatMessage {
  ChatMessage({
    required this.question,
    required this.machineCode,
    required this.answer,
    required this.boundingBoxes,
    required this.askedAt,
    this.isError = false,
  });

  final String question;
  final String? machineCode;
  final AnswerResult answer;
  final List<Rect> boundingBoxes;
  final DateTime askedAt;

  /// True when the answer was generated locally as a fallback (API 500 / offline).
  final bool isError;
}

// ─────────────────────────────────────────────────────────────────────────────
// SnapEntry — a single captured/uploaded image with its own Q&A thread
// ─────────────────────────────────────────────────────────────────────────────

class SnapEntry {
  SnapEntry({
    required this.bytes,
    required this.fileName,
    required this.capturedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  final Uint8List bytes;
  final String fileName;
  final DateTime capturedAt;
  final List<ChatMessage> messages;

  /// Returns a copy of this entry with the supplied message appended.
  SnapEntry copyWithMessage(ChatMessage message) => SnapEntry(
        bytes: bytes,
        fileName: fileName,
        capturedAt: capturedAt,
        messages: List<ChatMessage>.from(messages)..add(message),
      );
}
