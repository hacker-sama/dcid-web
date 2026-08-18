import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme.dart';
import '../../../data/models/snap_entry.dart';

/// Floating card container for machine code input and question prompt with image attachment.
class SnapInputFooter extends ConsumerStatefulWidget {
  const SnapInputFooter({
    super.key,
    required this.snap,
    required this.isAsking,
    required this.picking,
    required this.questionController,
    required this.questionFocusNode,
    required this.machineCodeController,
    required this.machineCodeScanned,
    required this.onMachineCodeChanged,
    required this.onClearMachineCode,
    required this.onOpenImageSourcePicker,
    required this.onAskQuestion,
  });

  final SnapEntry? snap;
  final bool isAsking;
  final bool picking;
  final TextEditingController questionController;
  final FocusNode questionFocusNode;
  final TextEditingController machineCodeController;
  final bool machineCodeScanned;
  final ValueChanged<String> onMachineCodeChanged;
  final VoidCallback onClearMachineCode;
  final VoidCallback onOpenImageSourcePicker;
  final VoidCallback onAskQuestion;

  @override
  ConsumerState<SnapInputFooter> createState() => _SnapInputFooterState();
}

class _SnapInputFooterState extends ConsumerState<SnapInputFooter> {
  bool _inputFocused = false;

  @override
  void initState() {
    super.initState();
    widget.questionFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SnapInputFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionFocusNode != widget.questionFocusNode) {
      oldWidget.questionFocusNode.removeListener(_onFocusChange);
      widget.questionFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.questionFocusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _inputFocused = widget.questionFocusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSnap = widget.snap != null;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final accent = accentFor(context);
    final accentGlow = accentGlowFor(context);
    final strings = ref.watch(appStringsProvider);

    final cardBg = isDark ? kDarkCard : Colors.white;
    final borderColor = _inputFocused
        ? accent.withValues(alpha: 0.6)
        : (isDark
            ? kDarkBorder
            : scheme.outlineVariant.withValues(alpha: 0.45));

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (_inputFocused)
                BoxShadow(color: accentGlow, blurRadius: 16, spreadRadius: 0)
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMachineCodeRow(scheme, accent, strings),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? kDarkBorder
                    : scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              _buildMessageRow(hasSnap, scheme, accent, strings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineCodeRow(ColorScheme scheme, Color accent, dynamic strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
      child: Row(
        children: [
          Icon(
            Icons.memory_outlined,
            size: 15,
            color: widget.machineCodeScanned
                ? Colors.green.shade600
                : scheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.machineCodeController,
              onChanged: widget.onMachineCodeChanged,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: strings.machineCodeHint,
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          if (widget.machineCodeScanned)
            GestureDetector(
              onTap: widget.onClearMachineCode,
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      widget.machineCodeController.text.trim(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.close_rounded,
                        size: 11, color: Colors.green.shade400),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(bool hasSnap, ColorScheme scheme, Color accent, dynamic strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Tooltip(
            message: strings.snapTooltip,
            child: SnapAttachButton(
              picking: widget.picking,
              accent: accent,
              onTap: widget.picking ? null : widget.onOpenImageSourcePicker,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  if (hasSnap && !widget.isAsking && widget.questionController.text.trim().isNotEmpty) {
                    widget.onAskQuestion();
                  }
                },
                const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
                  if (hasSnap && !widget.isAsking && widget.questionController.text.trim().isNotEmpty) {
                    widget.onAskQuestion();
                  }
                },
              },
              child: TextField(
                controller: widget.questionController,
                focusNode: widget.questionFocusNode,
                enabled: hasSnap && !widget.isAsking,
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: hasSnap
                      ? strings.askAboutDevicePhoto
                      : strings.addImageFirstToAsk,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.35),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (hasSnap && !widget.isAsking)
                    ? (_) {
                        if (widget.questionController.text.trim().isNotEmpty) {
                          widget.onAskQuestion();
                        }
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SnapSendButton(
            onTap: (hasSnap && !widget.isAsking) ? widget.onAskQuestion : null,
            isLoading: widget.isAsking,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class SnapAttachButton extends StatefulWidget {
  const SnapAttachButton({
    super.key,
    required this.picking,
    required this.accent,
    required this.onTap,
  });

  final bool picking;
  final Color accent;
  final VoidCallback? onTap;

  @override
  State<SnapAttachButton> createState() => _SnapAttachButtonState();
}

class _SnapAttachButtonState extends State<SnapAttachButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered
                ? widget.accent.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Center(
            child: widget.picking
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.accent,
                    ),
                  )
                : Icon(
                    Icons.add_circle_outline_rounded,
                    size: 22,
                    color: _hovered
                        ? widget.accent
                        : widget.accent.withValues(alpha: 0.7),
                  ),
          ),
        ),
      ),
    );
  }
}

class SnapSendButton extends StatefulWidget {
  const SnapSendButton({
    super.key,
    required this.onTap,
    required this.isLoading,
    required this.accent,
  });

  final VoidCallback? onTap;
  final bool isLoading;
  final Color accent;

  @override
  State<SnapSendButton> createState() => _SnapSendButtonState();
}

class _SnapSendButtonState extends State<SnapSendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? (_hovered
                    ? widget.accent.withValues(alpha: 0.85)
                    : widget.accent)
                : widget.accent.withValues(alpha: 0.25),
            boxShadow: enabled && _hovered
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
