import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme.dart';
import '../../data/models/feedback_admin_item.dart';
import '../../state/providers.dart';

class FeedbackAdminView extends ConsumerStatefulWidget {
  const FeedbackAdminView({super.key});

  @override
  ConsumerState<FeedbackAdminView> createState() => _FeedbackAdminViewState();
}

class _FeedbackAdminViewState extends ConsumerState<FeedbackAdminView> {
  final _searchController = TextEditingController();
  int? _selectedFeedbackFilter; // null = all, 1 = helpful, -1 = not helpful
  bool _isLoading = false;
  String? _errorMessage;
  List<FeedbackAdminItem> _feedbacks = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(analyticsRepositoryProvider);
      final list = await repo.getFeedbacks(
        feedback: _selectedFeedbackFilter,
        page: 0,
        size: 100,
      );
      setState(() {
        _feedbacks = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load feedbacks: $e';
        _isLoading = false;
      });
    }
  }

  List<FeedbackAdminItem> get _filteredFeedbacks {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _feedbacks;
    return _feedbacks.where((item) {
      final matchQ = item.question.toLowerCase().contains(query);
      final matchA = item.answerPreview?.toLowerCase().contains(query) ?? false;
      final matchNote = item.feedbackNote?.toLowerCase().contains(query) ?? false;
      final matchUser = item.actorUsername.toLowerCase().contains(query);
      return matchQ || matchA || matchNote || matchUser;
    }).toList();
  }

  void _showDetailDialog(FeedbackAdminItem item) {
    final strings = ref.read(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final df = DateFormat('dd/MM/yyyy HH:mm:ss');
    final timeStr = item.feedbackAt != null
        ? df.format(item.feedbackAt!)
        : df.format(item.createdAt);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(item.feedback == 1 ? '👍 ${strings.helpful}' : '👎 ${strings.notHelpful}'),
            const Spacer(),
            Text(
              timeStr,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User & Confidence
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${strings.feedbackUserLabel}: ${item.actorUsername}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    if (item.confidence != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (item.confidence! >= 0.7 ? Colors.green : Colors.orange)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${strings.confidence}: ${(item.confidence! * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.confidence! >= 0.7 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),

                // Question
                Text(
                  strings.questionDetailLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  item.question,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),

                // Answer preview
                if (item.answerPreview != null && item.answerPreview!.isNotEmpty) ...[
                  Text(
                    strings.answerDetailLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      item.answerPreview!,
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Feedback Note
                if (item.feedbackNote != null && item.feedbackNote!.trim().isNotEmpty) ...[
                  Text(
                    '${strings.feedbackNoteLabel}:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (item.feedback == 1 ? Colors.green : Colors.red).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (item.feedback == 1 ? Colors.green : Colors.red).withValues(alpha: 0.25),
                      ),
                    ),
                    child: SelectableText(
                      item.feedbackNote!,
                      style: TextStyle(
                        fontSize: 13,
                        color: item.feedback == 1 ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ColorScheme scheme,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 0 : 1,
      color: isDark ? kDarkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? color.withValues(alpha: 0.35) : color.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.45 : 0.28),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.watch(appStringsProvider);

    final total = _feedbacks.length;
    final helpfulCount = _feedbacks.where((f) => f.feedback == 1).length;
    final unhelpfulCount = _feedbacks.where((f) => f.feedback == -1).length;
    final satisfactionRate = total > 0 ? (helpfulCount / total * 100).toStringAsFixed(1) : '100.0';

    final items = _filteredFeedbacks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Summary Cards ───────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final cards = [
                _buildStatCard(
                  title: strings.totalFeedbacks,
                  value: '$total',
                  icon: Icons.rate_review_rounded,
                  color: Colors.blue.shade700,
                  scheme: scheme,
                ),
                _buildStatCard(
                  title: strings.helpfulCountLabel,
                  value: '$helpfulCount',
                  icon: Icons.thumb_up_rounded,
                  color: Colors.green.shade700,
                  scheme: scheme,
                ),
                _buildStatCard(
                  title: strings.notHelpfulCountLabel,
                  value: '$unhelpfulCount',
                  icon: Icons.thumb_down_rounded,
                  color: Colors.red.shade700,
                  scheme: scheme,
                ),
                _buildStatCard(
                  title: strings.satisfactionRate,
                  value: '$satisfactionRate%',
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  color: Colors.teal.shade700,
                  scheme: scheme,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),
          const SizedBox(height: 16),

          // ── 2. Toolbar (Search & Filter) ───────────────────────────────────
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  final searchInput = SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 13, color: scheme.onSurface),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: strings.searchFeedbackPlaceholder,
                        hintStyle: TextStyle(fontSize: 13, color: scheme.outline),
                        prefixIcon: Icon(Icons.search, size: 18, color: scheme.outline),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                  );

                  final ratingDropdown = SizedBox(
                    width: isMobile ? double.infinity : 200,
                    height: 44,
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedFeedbackFilter,
                      borderRadius: BorderRadius.circular(10),
                      style: TextStyle(fontSize: 13, color: scheme.onSurface),
                      icon: Icon(Icons.arrow_drop_down, color: scheme.outline),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: strings.feedbackRating,
                        labelStyle: TextStyle(fontSize: 13, color: scheme.outline),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.primary, width: 1.5),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(strings.filterAllRatings, style: const TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 1, child: Text(strings.filterHelpfulOnly, style: const TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: -1, child: Text(strings.filterNotHelpfulOnly, style: const TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedFeedbackFilter = v);
                        _fetchFeedbacks();
                      },
                    ),
                  );

                  final refreshBtn = SizedBox(
                    height: 44,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _fetchFeedbacks,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(strings.refresh, style: const TextStyle(fontSize: 13)),
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchInput,
                        const SizedBox(height: 10),
                        ratingDropdown,
                        const SizedBox(height: 10),
                        refreshBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: searchInput),
                      const SizedBox(width: 12),
                      ratingDropdown,
                      const SizedBox(width: 12),
                      refreshBtn,
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 3. Data Table ──────────────────────────────────────────────────
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, style: TextStyle(color: scheme.error)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _fetchFeedbacks,
                      icon: const Icon(Icons.refresh),
                      label: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rate_review_outlined, size: 48, color: scheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      strings.noFeedbacksFound,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowHeight: 48,
                              dataRowMinHeight: 52,
                              dataRowMaxHeight: 64,
                              headingRowColor: WidgetStateProperty.all(
                                scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              ),
                              columns: [
                                DataColumn(label: Text(strings.columnTime, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(strings.columnUser, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(strings.columnRating, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(strings.columnQuestion, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(strings.columnFeedbackNote, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(strings.columnConfidence, style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: items.map((f) {
                                final timeStr = f.feedbackAt != null
                                    ? DateFormat('dd/MM HH:mm').format(f.feedbackAt!)
                                    : DateFormat('dd/MM HH:mm').format(f.createdAt);

                                return DataRow(
                                  onSelectChanged: (_) => _showDetailDialog(f),
                                  cells: [
                                    // Time
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.schedule_rounded, size: 13, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                          const SizedBox(width: 4),
                                          Text(timeStr, style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    // User
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person_outline_rounded, size: 14, color: scheme.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            f.actorUsername,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Rating
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (f.feedback == 1 ? Colors.green : Colors.red)
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: (f.feedback == 1 ? Colors.green : Colors.red)
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              f.feedback == 1 ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                                              size: 13,
                                              color: f.feedback == 1 ? Colors.green.shade700 : Colors.red.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              f.feedback == 1 ? strings.helpful : strings.notHelpful,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: f.feedback == 1 ? Colors.green.shade700 : Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Question
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 240),
                                        child: Text(
                                          f.question,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    // Note
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 200),
                                        child: Text(
                                          f.feedbackNote ?? '—',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: f.feedbackNote != null ? FontStyle.italic : FontStyle.normal,
                                            color: f.feedbackNote != null ? scheme.onSurface : scheme.outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Confidence
                                    DataCell(
                                      f.confidence != null
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.analytics_outlined,
                                                  size: 13,
                                                  color: f.confidence! >= 0.7 ? Colors.green : Colors.orange,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${(f.confidence! * 100).toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: f.confidence! >= 0.7 ? Colors.green : Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text('—'),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        strings.showingFeedbacksCount(items.length),
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
