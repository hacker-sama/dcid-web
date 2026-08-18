package vn.dcid.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.dcid.domain.entity.QueryLog;
import vn.dcid.domain.enums.DocumentCategory;
import vn.dcid.dto.response.AnalyticsDTO;
import vn.dcid.repository.DocumentRepository;
import vn.dcid.repository.DocumentVersionRepository;
import vn.dcid.repository.QueryLogRepository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AnalyticsService {

    private final DocumentRepository documentRepository;
    private final DocumentVersionRepository versionRepository;
    private final QueryLogRepository queryLogRepository;

    public AnalyticsService(DocumentRepository documentRepository,
                            DocumentVersionRepository versionRepository,
                            QueryLogRepository queryLogRepository) {
        this.documentRepository = documentRepository;
        this.versionRepository = versionRepository;
        this.queryLogRepository = queryLogRepository;
    }

    @Transactional(readOnly = true)
    public AnalyticsDTO getSystemAnalytics() {
        long totalDocs = documentRepository.count();
        long totalVersions = versionRepository.count();
        long totalQueries = queryLogRepository.count();

        Double avgConf = queryLogRepository.calculateAvgConfidence();
        double avgConfidence = avgConf != null ? Math.round(avgConf * 1000.0) / 1000.0 : 0.0;

        Double avgLat = queryLogRepository.calculateAvgLatencyMs();
        long avgLatencyMs = avgLat != null ? Math.round(avgLat) : 0L;

        long lockedQueries = queryLogRepository.countByLocked(true);
        long numericRuleQueries = queryLogRepository.countByNumericRuleHit(true);

        double lockedRate = totalQueries > 0
                ? Math.round(((double) lockedQueries / totalQueries) * 1000.0) / 10.0
                : 0.0;
        double numericRuleRate = totalQueries > 0
                ? Math.round(((double) numericRuleQueries / totalQueries) * 1000.0) / 10.0
                : 0.0;

        // 7-day query trend
        Instant sevenDaysAgo = Instant.now().minus(7, ChronoUnit.DAYS);
        List<QueryLog> recentQueries = queryLogRepository.findQueriesSince(sevenDaysAgo);

        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        ZoneId zone = ZoneId.systemDefault();

        Map<String, Long> dateCountMap = new LinkedHashMap<>();
        LocalDate today = LocalDate.now();
        for (int i = 6; i >= 0; i--) {
            dateCountMap.put(today.minusDays(i).format(dtf), 0L);
        }

        for (QueryLog q : recentQueries) {
            String dateStr = q.getCreatedAt().atZone(zone).format(dtf);
            dateCountMap.computeIfPresent(dateStr, (k, v) -> v + 1);
        }

        List<AnalyticsDTO.DailyQueryCount> queriesByDay = dateCountMap.entrySet().stream()
                .map(e -> new AnalyticsDTO.DailyQueryCount(e.getKey(), e.getValue()))
                .toList();

        // Documents by category
        List<Object[]> catCounts = documentRepository.countDocumentsGroupedByCategory();
        List<AnalyticsDTO.CategoryCount> documentsByCategory = new ArrayList<>();
        for (Object[] row : catCounts) {
            if (row != null && row.length >= 2 && row[0] != null) {
                DocumentCategory cat = (DocumentCategory) row[0];
                Long count = (Long) row[1];
                documentsByCategory.add(new AnalyticsDTO.CategoryCount(cat.name(), count));
            }
        }

        // Top queried machines from query log
        Map<String, Long> machineCounts = new HashMap<>();
        // Group by question / machine if needed, or top matched docs
        List<AnalyticsDTO.MachineQueryCount> topMachines = machineCounts.entrySet().stream()
                .sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
                .limit(5)
                .map(e -> new AnalyticsDTO.MachineQueryCount(e.getKey(), e.getValue()))
                .toList();

        return new AnalyticsDTO(
                totalDocs,
                totalVersions,
                totalQueries,
                avgConfidence,
                avgLatencyMs,
                lockedQueries,
                numericRuleQueries,
                lockedRate,
                numericRuleRate,
                queriesByDay,
                documentsByCategory,
                topMachines
        );
    }
}
