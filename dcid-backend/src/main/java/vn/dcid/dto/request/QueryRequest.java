package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

/** App → BE: câu hỏi tra cứu kèm lịch sử hội thoại và tài liệu mục tiêu (API-CONTRACT.md §2.1). */
public record QueryRequest(
        @NotBlank(message = "question is required")
        @Size(max = 2000, message = "question too long") String question,
        String machineCode,
        boolean reasoningMode,
        List<UUID> selectedVersionIds,
        List<ChatMessageDTO> history
) {
}
