package vn.dcid.dto.response;

import java.time.Instant;
import java.util.UUID;

public record ApplicationDTO(
        UUID id,
        UUID applicantId,
        UUID procedureTypeId,
        String status,
        UUID assignedOfficerId,
        Instant submittedAt,
        Instant completedAt,
        Instant estimatedCompletionAt,
        Boolean isUrgent,
        Instant createdAt,
        Instant updatedAt
) {
}
