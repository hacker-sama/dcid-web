package vn.dcid.dto.response;

import java.util.List;
import java.util.UUID;

/**
 * BE → App: kết quả hỏi–đáp (API-CONTRACT.md §2.3).
 * Shape phải khớp model Flutter đang parse: answer / confidence / guard{locked,numericRule} / citations[].
 */
public record AnswerDTO(
        UUID queryLogId,
        String answer,
        double confidence,
        Guard guard,
        List<Citation> citations
) {
    public record Guard(boolean locked, boolean numericRule, boolean reasoningMode) {
    }

    public record Citation(UUID versionId, int pageNo, String bboxKey, String snippet) {
    }

    /** Câu trả lời bị guardrail khóa (dùng khi không có tài liệu phù hợp quyền / độ tin cậy thấp). */
    public static AnswerDTO locked(String message) {
        return new AnswerDTO(null, message, 0.0, new Guard(true, false, false), List.of());
    }
}
