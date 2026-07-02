package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** App → BE: câu hỏi tra cứu (API-CONTRACT.md §2.1). */
public record QueryRequest(
        @NotBlank(message = "question is required")
        @Size(max = 2000, message = "question too long") String question,
        String machineCode
) {
}
