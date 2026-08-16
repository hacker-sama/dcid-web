class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalDocuments,
    required this.totalVersions,
    required this.totalQueries,
    required this.avgConfidence,
    required this.avgLatencyMs,
    required this.totalLockedQueries,
    required this.totalNumericRuleQueries,
    required this.lockedRate,
    required this.numericRuleRate,
    required this.queriesByDay,
    required this.documentsByCategory,
    required this.topMachines,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalDocuments: (json['totalDocuments'] as num?)?.toInt() ?? 0,
      totalVersions: (json['totalVersions'] as num?)?.toInt() ?? 0,
      totalQueries: (json['totalQueries'] as num?)?.toInt() ?? 0,
      avgConfidence: (json['avgConfidence'] as num?)?.toDouble() ?? 0.0,
      avgLatencyMs: (json['avgLatencyMs'] as num?)?.toInt() ?? 0,
      totalLockedQueries: (json['totalLockedQueries'] as num?)?.toInt() ?? 0,
      totalNumericRuleQueries: (json['totalNumericRuleQueries'] as num?)?.toInt() ?? 0,
      lockedRate: (json['lockedRate'] as num?)?.toDouble() ?? 0.0,
      numericRuleRate: (json['numericRuleRate'] as num?)?.toDouble() ?? 0.0,
      queriesByDay: (json['queriesByDay'] as List<dynamic>?)
              ?.map((e) => DailyQueryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      documentsByCategory: (json['documentsByCategory'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topMachines: (json['topMachines'] as List<dynamic>?)
              ?.map((e) => MachineQueryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final int totalDocuments;
  final int totalVersions;
  final int totalQueries;
  final double avgConfidence;
  final int avgLatencyMs;
  final int totalLockedQueries;
  final int totalNumericRuleQueries;
  final double lockedRate;
  final double numericRuleRate;
  final List<DailyQueryCount> queriesByDay;
  final List<CategoryCount> documentsByCategory;
  final List<MachineQueryCount> topMachines;
}

class DailyQueryCount {
  const DailyQueryCount({required this.date, required this.count});

  factory DailyQueryCount.fromJson(Map<String, dynamic> json) {
    return DailyQueryCount(
      date: json['date']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String date;
  final int count;
}

class CategoryCount {
  const CategoryCount({required this.category, required this.count});

  factory CategoryCount.fromJson(Map<String, dynamic> json) {
    return CategoryCount(
      category: json['category']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String category;
  final int count;
}

class MachineQueryCount {
  const MachineQueryCount({required this.machineCode, required this.count});

  factory MachineQueryCount.fromJson(Map<String, dynamic> json) {
    return MachineQueryCount(
      machineCode: json['machineCode']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String machineCode;
  final int count;
}
