package vn.dcid.ai.dto;

import java.util.UUID;

/** Một trích dẫn nguồn: version + trang (+ crop bbox, đoạn text nếu có). */
public record AiCitation(
        UUID versionId,
        int pageNo,
        String bboxKey,
        String snippet
) {
}
