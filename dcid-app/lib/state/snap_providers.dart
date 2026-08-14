import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/rendering.dart' show Rect;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/answer_result.dart';
import '../data/models/snap_entry.dart';
import 'providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SnapState — immutable value object held by the notifier
// ─────────────────────────────────────────────────────────────────────────────

class SnapState {
  const SnapState({
    this.snaps = const [],
    this.selectedIndex,
  });

  /// All uploaded / captured images, newest first.
  final List<SnapEntry> snaps;

  /// Index into [snaps] of the currently active image, or null when empty.
  final int? selectedIndex;

  SnapEntry? get selectedSnap =>
      (selectedIndex != null && selectedIndex! < snaps.length)
          ? snaps[selectedIndex!]
          : null;

  SnapState copyWith({
    List<SnapEntry>? snaps,
    // Sentinel object allows explicitly setting selectedIndex to null.
    Object? selectedIndex = _unset,
  }) =>
      SnapState(
        snaps: snaps ?? this.snaps,
        selectedIndex: identical(selectedIndex, _unset)
            ? this.selectedIndex
            : selectedIndex as int?,
      );

  static const _unset = Object();
}

// ─────────────────────────────────────────────────────────────────────────────
// SnapNotifier — global source of truth for Snap & Ask session state.
//
// Persistence strategy (two layers):
//   1. In-memory (Riverpod NotifierProvider, app lifetime):
//      Survives tab switches because StatefulShellRoute.indexedStack keeps
//      all branch widgets alive; this notifier is never auto-disposed.
//   2. FlutterSecureStorage (localStorage on web):
//      Survives full page refreshes. Images stored as base64 strings.
//      Max [_maxStoredSnaps] images to stay within localStorage limits.
// ─────────────────────────────────────────────────────────────────────────────

class SnapNotifier extends Notifier<SnapState> {
  static const _storageKey = 'snap_ask_session_v1';

  /// Maximum number of snaps persisted to storage to avoid hitting the
  /// ~5 MB localStorage limit (each 800×800 80%-quality JPEG ≈ 200–270 KB
  /// as Base64).
  static const _maxStoredSnaps = 5;

  @override
  SnapState build() {
    // Kick off async storage load without blocking the first render.
    _loadFromStorage();
    return const SnapState();
  }

  // ── Public mutations ──────────────────────────────────────────────────────

  /// Insert a new image at the front and make it the active selection.
  void addSnap(Uint8List bytes, String fileName) {
    addSnaps([(bytes: bytes, fileName: fileName)]);
  }

  /// Insert multiple new images at the front and make the first inserted image the active selection.
  void addSnaps(List<({Uint8List bytes, String fileName})> items) {
    if (items.isEmpty) return;
    final now = DateTime.now();
    final newEntries = items
        .map((item) => SnapEntry(
              bytes: item.bytes,
              fileName: item.fileName,
              capturedAt: now,
            ))
        .toList();
    state = state.copyWith(
      snaps: [...newEntries, ...state.snaps],
      selectedIndex: 0,
    );
    _saveToStorage();
  }

  /// Change the active selection.
  void selectSnap(int index) {
    if (index < 0 || index >= state.snaps.length) return;
    if (state.selectedIndex == index) return;
    state = state.copyWith(selectedIndex: index);
    _saveToStorage();
  }

  /// Remove an image and adjust the active selection.
  void deleteSnap(int index) {
    if (index < 0 || index >= state.snaps.length) return;
    final updated = List<SnapEntry>.from(state.snaps)..removeAt(index);

    int? nextSelected;
    if (updated.isEmpty) {
      nextSelected = null;
    } else if (state.selectedIndex == null) {
      nextSelected = null;
    } else if (state.selectedIndex! >= updated.length) {
      nextSelected = updated.length - 1;
    } else {
      nextSelected = state.selectedIndex;
    }

    state = state.copyWith(snaps: updated, selectedIndex: nextSelected);
    _saveToStorage();
  }

  /// Append a Q&A message to the snap at [snapIndex].
  void addMessage(int snapIndex, ChatMessage message) {
    if (snapIndex < 0 || snapIndex >= state.snaps.length) return;
    final updated = List<SnapEntry>.from(state.snaps);
    updated[snapIndex] = updated[snapIndex].copyWithMessage(message);
    state = state.copyWith(snaps: updated);
    _saveToStorage();
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<void> _loadFromStorage() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = _snapStateFromJson(json);
      if (loaded.snaps.isNotEmpty) {
        state = loaded;
      }
    } catch (_) {
      // Corrupted or incompatible data — clear and start fresh.
      try {
        final storage = ref.read(secureStorageProvider);
        await storage.delete(key: _storageKey);
      } catch (_) {}
    }
  }

  /// Fire-and-forget persistence so mutations never block the UI.
  void _saveToStorage() {
    _persistAsync();
  }

  Future<void> _persistAsync() async {
    try {
      final storage = ref.read(secureStorageProvider);
      // Trim to the most recent N snaps to stay within storage limits.
      final trimmed = state.copyWith(
        snaps: state.snaps.take(_maxStoredSnaps).toList(),
      );
      await storage.write(
        key: _storageKey,
        value: jsonEncode(_snapStateToJson(trimmed)),
      );
    } catch (_) {
      // Storage full or unavailable — silently skip.
    }
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  static Map<String, dynamic> _snapStateToJson(SnapState s) => {
        'selectedIndex': s.selectedIndex,
        'snaps': s.snaps.map(_snapEntryToJson).toList(),
      };

  static Map<String, dynamic> _snapEntryToJson(SnapEntry e) => {
        'fileName': e.fileName,
        'capturedAt': e.capturedAt.toIso8601String(),
        'bytesBase64': base64Encode(e.bytes),
        'messages': e.messages.map(_chatMessageToJson).toList(),
      };

  static Map<String, dynamic> _chatMessageToJson(ChatMessage m) => {
        'question': m.question,
        'machineCode': m.machineCode,
        'askedAt': m.askedAt.toIso8601String(),
        'isError': m.isError,
        // Rect stored as [left, top, right, bottom] for compact JSON.
        'boundingBoxes': m.boundingBoxes
            .map((r) => [r.left, r.top, r.right, r.bottom])
            .toList(),
        'answer': _answerResultToJson(m.answer),
      };

  static Map<String, dynamic> _answerResultToJson(AnswerResult a) => {
        'answer': a.answer,
        'confidence': a.confidence,
        'guard': {
          'locked': a.locked,
          'numericRule': a.numericRule,
          'reasoningMode': a.reasoningMode,
        },
        'citations': a.citations
            .map((c) => {
                  'versionId': c.versionId,
                  'pageNo': c.pageNo,
                  'bboxKey': c.bboxKey,
                  'snippet': c.snippet,
                })
            .toList(),
      };

  // ── Deserialization ───────────────────────────────────────────────────────

  static SnapState _snapStateFromJson(Map<String, dynamic> j) {
    final snapsList =
        (j['snaps'] as List<dynamic>? ?? []).map(_snapEntryFromJson).toList();
    return SnapState(
      snaps: snapsList,
      selectedIndex: j['selectedIndex'] as int?,
    );
  }

  static SnapEntry _snapEntryFromJson(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final bytes = base64Decode(map['bytesBase64'] as String);
    final messages =
        (map['messages'] as List<dynamic>? ?? []).map(_chatMessageFromJson).toList();
    return SnapEntry(
      bytes: bytes,
      fileName: map['fileName'] as String,
      capturedAt: DateTime.parse(map['capturedAt'] as String),
      messages: messages,
    );
  }

  static ChatMessage _chatMessageFromJson(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final boxes = (map['boundingBoxes'] as List<dynamic>? ?? []).map((b) {
      final coords = b as List<dynamic>;
      return Rect.fromLTRB(
        (coords[0] as num).toDouble(),
        (coords[1] as num).toDouble(),
        (coords[2] as num).toDouble(),
        (coords[3] as num).toDouble(),
      );
    }).toList();
    return ChatMessage(
      question: map['question'] as String? ?? '',
      machineCode: map['machineCode'] as String?,
      askedAt: map['askedAt'] != null
          ? DateTime.parse(map['askedAt'] as String)
          : DateTime.now(),
      isError: map['isError'] == true,
      boundingBoxes: boxes,
      answer: AnswerResult.fromJson(
          (map['answer'] as Map<String, dynamic>?) ?? const {}),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final snapProvider =
    NotifierProvider<SnapNotifier, SnapState>(SnapNotifier.new);
