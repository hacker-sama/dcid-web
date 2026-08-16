package vn.dcid.dto.response;

import java.util.List;

public record AnalyticsDTO(
        long totalDocuments,
        long totalVersions,
        long totalQueries,
        double avgConfidence,
        long avgLatencyMs,
        long totalLockedQueries,
        long totalNumericRuleQueries,
        double lockedRate,
        double numericRuleRate,
        List<DailyQueryCount> queriesByDay,
        List<CategoryCount> documentsByCategory,
        List<MachineQueryCount> topMachines
) {
    public record DailyQueryCount(String date, long count) {}
    public record CategoryCount(String category, long count) {}
    public record MachineQueryCount(String machineCode, long count) {}
}
