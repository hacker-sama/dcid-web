import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/localization/locale_controller.dart';
import '../../data/models/query_history_item.dart';
import '../../state/providers.dart';

enum _DateFilterMode { all, today, last7Days, last30Days, custom }
enum _FeedbackFilterMode { all, helpful, notHelpful, unrated, locked }

/// Provider tải lịch sử câu hỏi, tự refresh khi rebuild.
final _historyProvider = FutureProvider.autoDispose<List<QueryHistoryItem>>((ref) async {
  final raw = await ref.watch(docsRepositoryProvider).getQueryHistory(page: 0, size: 50);
  return raw
      .map((e) => QueryHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Màn hình lịch sử câu hỏi cá nhân với tìm kiếm, lọc theo ngày và đánh giá.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  _DateFilterMode _dateFilter = _DateFilterMode.all;
  DateTimeRange? _customDateRange;
  _FeedbackFilterMode _feedbackFilter = _FeedbackFilterMode.all;
  final Set<String> _expandedItemIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateFilter = _DateFilterMode.all;
      _customDateRange = null;
      _feedbackFilter = _FeedbackFilterMode.all;
    });
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _dateFilter != _DateFilterMode.all ||
      _feedbackFilter != _FeedbackFilterMode.all;

  List<QueryHistoryItem> _filterItems(List<QueryHistoryItem> items) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return items.where((item) {
      // 1. Text Search Filter
      if (query.isNotEmpty) {
        final matchesQuestion = item.question.toLowerCase().contains(query);
        final matchesAnswer = item.answerPreview?.toLowerCase().contains(query) ?? false;
        final matchesNote = item.feedbackNote?.toLowerCase().contains(query) ?? false;
        if (!matchesQuestion && !matchesAnswer && !matchesNote) {
          return false;
        }
      }

      // 2. Date Filter
      final itemDate = item.createdAt;
      switch (_dateFilter) {
        case _DateFilterMode.all:
          break;
        case _DateFilterMode.today:
          final isSameDay = itemDate.year == now.year &&
              itemDate.month == now.month &&
              itemDate.day == now.day;
          if (!isSameDay) return false;
          break;
        case _DateFilterMode.last7Days:
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          if (itemDate.isBefore(sevenDaysAgo)) return false;
          break;
        case _DateFilterMode.last30Days:
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          if (itemDate.isBefore(thirtyDaysAgo)) return false;
          break;
        case _DateFilterMode.custom:
          if (_customDateRange != null) {
            final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
            final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
            if (itemDate.isBefore(start) || itemDate.isAfter(end)) return false;
          }
          break;
      }

      // 3. Feedback / Status Filter
      switch (_feedbackFilter) {
        case _FeedbackFilterMode.all:
          break;
        case _FeedbackFilterMode.helpful:
          if (item.feedback != 1) return false;
          break;
        case _FeedbackFilterMode.notHelpful:
          if (item.feedback != -1) return false;
          break;
        case _FeedbackFilterMode.unrated:
          if (item.feedback != null) return false;
          break;
        case _FeedbackFilterMode.locked:
          if (!item.locked) return false;
          break;
      }

      return true;
    }).toList();
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter = _DateFilterMode.custom;
        _customDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(_historyProvider);
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.historyTitle),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: strings.refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_historyProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(_historyProvider),
          strings: strings,
        ),
        data: (allItems) {
          if (allItems.isEmpty) {
            return _EmptyState(scheme: scheme, strings: strings);
          }

          final filteredItems = _filterItems(allItems);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_historyProvider),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Search & Filter Controls ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Search Bar
                      TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 14, color: scheme.onSurface),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: strings.searchHistoryPlaceholder,
                          hintStyle: TextStyle(fontSize: 13, color: scheme.outline),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: scheme.outline),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: scheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 2. Date Filter Chips Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text(
                              '${strings.dateRange}: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _buildDateChip(
                              label: strings.filterAllDates,
                              mode: _DateFilterMode.all,
                              scheme: scheme,
                            ),
                            const SizedBox(width: 6),
                            _buildDateChip(
                              label: strings.filterToday,
                              mode: _DateFilterMode.today,
                              scheme: scheme,
                            ),
                            const SizedBox(width: 6),
                            _buildDateChip(
                              label: strings.filter7Days,
                              mode: _DateFilterMode.last7Days,
                              scheme: scheme,
                            ),
                            const SizedBox(width: 6),
                            _buildDateChip(
                              label: strings.filter30Days,
                              mode: _DateFilterMode.last30Days,
                              scheme: scheme,
                            ),
                            const SizedBox(width: 6),
                            _buildCustomDateChip(strings: strings, scheme: scheme),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3. Status & Feedback Filter Chips Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusChip(
                              label: strings.filterAllFeedback,
                              mode: _FeedbackFilterMode.all,
                              scheme: scheme,
                            ),
                            const SizedBox(width: 6),
                            _buildStatusChip(
                              label: strings.filterHelpful,
                              mode: _FeedbackFilterMode.helpful,
                              scheme: scheme,
                              activeColor: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            _buildStatusChip(
                              label: strings.filterNotHelpful,
                              mode: _FeedbackFilterMode.notHelpful,
                              scheme: scheme,
                              activeColor: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            _buildStatusChip(
                              label: strings.filterUnrated,
                              mode: _FeedbackFilterMode.unrated,
                              scheme: scheme,
                            ),
                            const SizedBox(width: 6),
                            _buildStatusChip(
                              label: strings.filterLocked,
                              mode: _FeedbackFilterMode.locked,
                              scheme: scheme,
                              activeColor: Colors.orange,
                            ),
                          ],
                        ),
                      ),

                      // 4. Result Count & Reset Filters Toolbar
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings.showingHistoryCount(filteredItems.length, allItems.length),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_hasActiveFilters)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                              label: Text(strings.clearFilters, style: const TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── History List Area ─────────────────────────────────────────
                Expanded(
                  child: filteredItems.isEmpty
                      ? _NoMatchingState(
                          strings: strings,
                          scheme: scheme,
                          onClearFilters: _clearFilters,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isExpanded = _expandedItemIds.contains(item.id);
                            return _HistoryCard(
                              item: item,
                              isExpanded: isExpanded,
                              scheme: scheme,
                              strings: strings,
                              onToggleExpand: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedItemIds.remove(item.id);
                                  } else {
                                    _expandedItemIds.add(item.id);
                                  }
                                });
                              },
                              onFeedback: (helpful, note) => _submitFeedback(
                                context,
                                ref,
                                item.id,
                                helpful,
                                note,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required _DateFilterMode mode,
    required ColorScheme scheme,
  }) {
    final isSelected = _dateFilter == mode;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _dateFilter = mode;
            if (mode != _DateFilterMode.custom) {
              _customDateRange = null;
            }
          });
        }
      },
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildCustomDateChip({
    required dynamic strings,
    required ColorScheme scheme,
  }) {
    final isSelected = _dateFilter == _DateFilterMode.custom;
    final df = DateFormat('dd/MM');
    String label = strings.filterCustomDate;
    if (isSelected && _customDateRange != null) {
      label = '📅 ${df.format(_customDateRange!.start)} - ${df.format(_customDateRange!.end)}';
    }

    return ActionChip(
      avatar: Icon(
        Icons.calendar_month_rounded,
        size: 15,
        color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: isSelected ? scheme.primaryContainer.withValues(alpha: 0.6) : null,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: _pickCustomDateRange,
    );
  }

  Widget _buildStatusChip({
    required String label,
    required _FeedbackFilterMode mode,
    required ColorScheme scheme,
    Color? activeColor,
  }) {
    final isSelected = _feedbackFilter == mode;
    final color = activeColor ?? scheme.primary;

    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _feedbackFilter = selected ? mode : _FeedbackFilterMode.all;
        });
      },
      selectedColor: color.withValues(alpha: 0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? color : scheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? color : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Future<void> _submitFeedback(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool helpful,
    String? note,
  ) async {
    final strings = ref.read(appStringsProvider);
    try {
      await ref.read(docsRepositoryProvider).submitFeedback(id, helpful: helpful, note: note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(helpful ? strings.feedbackRecordedHelpful : strings.feedbackRecordedUnhelpful),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.invalidate(_historyProvider);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.feedbackFailed)),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern History Card
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.isExpanded,
    required this.scheme,
    required this.strings,
    required this.onToggleExpand,
    required this.onFeedback,
  });

  final QueryHistoryItem item;
  final bool isExpanded;
  final ColorScheme scheme;
  final dynamic strings;
  final VoidCallback onToggleExpand;
  final void Function(bool helpful, String? note) onFeedback;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt);
    final hasAnswer = item.answerPreview != null && item.answerPreview!.trim().isNotEmpty;
    final isAnswerLong = (item.answerPreview?.length ?? 0) > 160;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Question Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: item.locked
                        ? Colors.orange.withValues(alpha: 0.15)
                        : scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.locked ? Icons.lock_outline_rounded : Icons.help_outline_rounded,
                    size: 18,
                    color: item.locked ? Colors.orange : scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.question,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings.copy,
                  icon: Icon(Icons.content_copy_rounded, size: 16, color: scheme.outline),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.question));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.copyQuestionSuccess),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),

            // ── Answer Preview Section ───────────────────────────────────────
            if (hasAnswer) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.answerPreview!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                      maxLines: isExpanded ? null : 3,
                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    if (isAnswerLong) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: onToggleExpand,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: Text(
                                isExpanded ? strings.showLess : strings.showMore,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: strings.copy,
                            icon: Icon(Icons.copy_rounded, size: 14, color: scheme.outline),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: item.answerPreview!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(strings.copyAnswerSuccess),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Feedback Note Display if present ─────────────────────────────
            if (item.feedbackNote != null && item.feedbackNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${strings.feedbackNoteLabel}: ${item.feedbackNote}',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Metadata & Actions Footer ────────────────────────────────────
            Row(
              children: [
                // Timestamp
                Icon(Icons.schedule_rounded, size: 13, color: scheme.outline),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),

                // Confidence badge
                if (item.confidence != null) ...[
                  const SizedBox(width: 8),
                  _SmallBadge(
                    label: '${(item.confidence! * 100).toStringAsFixed(0)}%',
                    color: _confidenceColor(item.confidence!),
                    scheme: scheme,
                  ),
                ],

                // Locked badge
                if (item.locked) ...[
                  const SizedBox(width: 6),
                  _SmallBadge(label: 'Guarded', color: Colors.orange, scheme: scheme),
                ],

                const Spacer(),

                // Feedback actions
                if (item.feedback == null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FeedbackButton(
                        label: '👍',
                        tooltip: strings.helpful,
                        onTap: () => _confirmFeedback(context, true),
                        scheme: scheme,
                      ),
                      const SizedBox(width: 6),
                      _FeedbackButton(
                        label: '👎',
                        tooltip: strings.notHelpful,
                        onTap: () => _confirmFeedback(context, false),
                        scheme: scheme,
                      ),
                    ],
                  )
                else
                  _SmallBadge(
                    label: item.feedback == 1 ? '👍 ${strings.helpful}' : '👎 ${strings.notHelpful}',
                    color: item.feedback == 1 ? Colors.green : Colors.red,
                    scheme: scheme,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _confidenceColor(double c) {
    if (c >= 0.7) return Colors.green;
    if (c >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void _confirmFeedback(BuildContext context, bool helpful) {
    final noteCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(helpful ? '👍 ${strings.helpful}' : '👎 ${strings.notHelpful}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              helpful
                  ? strings.wasAnswerHelpful
                  : strings.notHelpful,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: strings.feedbackNotePrompt,
                hintText: strings.description,
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(strings.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onFeedback(helpful, noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
            },
            child: Text(strings.saveChanges),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color, required this.scheme});
  final String label;
  final Color color;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.label,
    required this.tooltip,
    required this.onTap,
    required this.scheme,
  });
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / No Results / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _NoMatchingState extends StatelessWidget {
  const _NoMatchingState({
    required this.scheme,
    required this.strings,
    required this.onClearFilters,
  });

  final ColorScheme scheme;
  final dynamic strings;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: scheme.outline),
            const SizedBox(height: 14),
            Text(
              strings.noMatchingHistory,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.noMatchingHistoryDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text(strings.clearFilters),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme, required this.strings});
  final ColorScheme scheme;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            strings.noHistoryTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.noHistorySubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry, required this.strings});
  final String message;
  final VoidCallback onRetry;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text('${strings.error}: $message'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: Text(strings.retry)),
        ],
      ),
    );
  }
}
