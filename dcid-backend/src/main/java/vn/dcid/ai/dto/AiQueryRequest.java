package vn.dcid.ai.dto;

import java.util.List;
import java.util.UUID;

/**
 * BE → AI: truy vấn RAG (xem API-CONTRACT.md §2.2).
 * {@code allowedVersionIds} do BE tính từ Postgres (ACTIVE + min_role ≤ vai user) — AI chỉ lọc theo đó.
 */
public record AiQueryRequest(
        String question,
        int topK,
        List<UUID> allowedVersionIds,
        String machineCode
) {
}
