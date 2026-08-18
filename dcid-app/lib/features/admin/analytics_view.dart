import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constrained_content.dart';
import '../../core/theme.dart';
import '../../data/models/analytics_summary.dart';
import '../../state/providers.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(analyticsFutureProvider);

    return asyncData.when(
      data: (data) => _AnalyticsContent(data: data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load analytics: $err'),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => ref.invalidate(analyticsFutureProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsContent extends ConsumerWidget {
  const _AnalyticsContent({required this.data});

  final AnalyticsSummary data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(analyticsFutureProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: ConstrainedContent(
          maxWidth: 1400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Analytics & KPIs',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Real-time metrics, guardrail adherence, and query performance.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => ref.invalidate(analyticsFutureProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Metric Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.6 : 1.3,
                    children: [
                      _MetricCard(
                        title: 'Total Queries',
                        value: '${data.totalQueries}',
                        subtitle: '${data.totalDocuments} Docs (${data.totalVersions} Versions)',
                        icon: Icons.question_answer_rounded,
                        color: kCobalt,
                      ),
                      _MetricCard(
                        title: 'Avg Confidence',
                        value: '${(data.avgConfidence * 100).toStringAsFixed(1)}%',
                        subtitle: 'Semantic & OCR evidence',
                        icon: Icons.verified_rounded,
                        color: Colors.green,
                      ),
                      _MetricCard(
                        title: 'Avg Latency',
                        value: '${data.avgLatencyMs} ms',
                        subtitle: 'CPU On-Premise Inference',
                        icon: Icons.speed_rounded,
                        color: Colors.orange,
                      ),
                      _MetricCard(
                        title: 'Guardrail Locked',
                        value: '${data.lockedRate.toStringAsFixed(1)}%',
                        subtitle: '${data.totalLockedQueries} queries blocked (Zero-tolerance)',
                        icon: Icons.security_rounded,
                        color: Colors.redAccent,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Charts Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _QueryTrendCard(data: data)),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _GuardrailPieCard(data: data)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _QueryTrendCard(data: data),
                      const SizedBox(height: 20),
                      _GuardrailPieCard(data: data),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Category & Technical breakdown
              _CategoryBreakdownCard(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      color: isDark ? kDarkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueryTrendCard extends StatelessWidget {
  const _QueryTrendCard({required this.data});

  final AnalyticsSummary data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final days = data.queriesByDay;
    final maxCount = days.isEmpty
        ? 10.0
        : days.map((d) => d.count.toDouble()).reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount < 5 ? 5.0 : maxCount * 1.3).ceilToDouble();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      color: isDark ? kDarkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7-Day Query Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kCobalt.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Daily Trend',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kCobalt,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: days.isEmpty
                  ? const Center(child: Text('No query data available'))
                  : BarChart(
                      BarChartData(
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final day = days[group.x.toInt()];
                              return BarTooltipItem(
                                '${day.date}\n${rod.toY.toInt()} queries',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                                final dateParts = days[idx].date.split('-');
                                final label = dateParts.length == 3
                                    ? '${dateParts[1]}/${dateParts[2]}'
                                    : days[idx].date;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (val, meta) {
                                return Text(
                                  val.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY > 10 ? (maxY / 4).roundToDouble() : 1,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: isDark ? Colors.white10 : Colors.black12,
                            strokeWidth: 1,
                          ),
                        ),
                        barGroups: days.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.count.toDouble(),
                                color: kCobalt,
                                width: 18,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardrailPieCard extends StatelessWidget {
  const _GuardrailPieCard({required this.data});

  final AnalyticsSummary data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final total = data.totalQueries;
    final locked = data.totalLockedQueries;
    final answered = total - locked;

    final answeredPercent = total > 0 ? (answered / total * 100).toStringAsFixed(1) : '100.0';
    final lockedPercent = total > 0 ? (locked / total * 100).toStringAsFixed(1) : '0.0';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      color: isDark ? kDarkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guardrail Reliability',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: total == 0
                  ? const Center(child: Text('No query logs recorded yet'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: (answered > 0 ? answered : 1).toDouble(),
                            title: '$answeredPercent%',
                            radius: 36,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (locked > 0)
                            PieChartSectionData(
                              color: Colors.redAccent,
                              value: locked.toDouble(),
                              title: '$lockedPercent%',
                              radius: 36,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(
                  color: Colors.green,
                  label: 'Verified Answers ($answered)',
                ),
                _LegendItem(
                  color: Colors.redAccent,
                  label: 'Guarded / Locked ($locked)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.data});

  final AnalyticsSummary data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      color: isDark ? kDarkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Categories Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            data.documentsByCategory.isEmpty
                ? const Text('No documents registered yet')
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: data.documentsByCategory.map((c) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: kCobalt,
                          child: Text(
                            '${c.count}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        label: Text(c.category),
                        backgroundColor: isDark ? Colors.white10 : Colors.black12.withValues(alpha: 0.05),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
