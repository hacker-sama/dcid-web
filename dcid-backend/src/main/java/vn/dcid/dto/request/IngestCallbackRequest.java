package vn.dcid.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.util.List;
import java.util.UUID;

/** AI → BE: kết quả ingest (API-CONTRACT.md §1.2). */
public record IngestCallbackRequest(
        @NotNull(message = "versionId is required") UUID versionId,
        @NotNull(message = "status is required")
        @Pattern(regexp = "READY|FAILED", message = "status must be READY or FAILED") String status,
        Integer pageCount,
        List<PageInfo> pages,
        String error
) {
    public record PageInfo(
            int pageNo,
            String imageKey,
            Integer width,
            Integer height,
            String ocrText
    ) {
    }
}
