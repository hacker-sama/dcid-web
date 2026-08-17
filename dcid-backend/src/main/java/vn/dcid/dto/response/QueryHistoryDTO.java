package vn.dcid.dto.response;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record QueryHistoryDTO(
        UUID id,
        String question,
        String answerPreview,
        BigDecimal confidence,
        Boolean locked,
        Boolean numericRuleHit,
        Integer latencyMs,
        Instant createdAt
) {}
