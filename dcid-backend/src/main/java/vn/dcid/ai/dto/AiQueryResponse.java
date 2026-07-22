package vn.dcid.ai.dto;

import java.util.List;

/** AI → BE: kết quả truy vấn (xem API-CONTRACT.md §2.2). */
public record AiQueryResponse(
        String answer,
        double confidence,
        AiGuard guard,
        List<AiCitation> citations,
        Integer latencyMs,
        String model
) {
}
