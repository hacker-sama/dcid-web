package vn.dcid.dto.response;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record FeedbackAdminDTO(
        UUID id,
        UUID actorId,
        String actorUsername,
        String question,
        String answerPreview,
        BigDecimal confidence,
        Boolean locked,
        Short feedback,
        String feedbackNote,
        Instant feedbackAt,
        Instant createdAt
) {}
