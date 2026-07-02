package vn.dcid.ai.dto;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/** BE → AI: kích hoạt OCR→chunk→embed→index cho một version (xem API-CONTRACT.md §1.1). */
public record AiIngestRequest(
        UUID versionId,
        UUID documentId,
        String storageKey,
        List<String> langs,
        Map<String, String> metadata
) {
}
