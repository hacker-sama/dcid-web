package vn.dcid.dto.response;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record ApplicationDetailDTO(
        UUID id,
        UUID applicantId,
        UUID procedureTypeId,
        String status,
        UUID assignedOfficerId,
        Instant submittedAt,
        Instant completedAt,
        Instant estimatedCompletionAt,
        String formData,
        String notes,
        Boolean isUrgent,
        Instant createdAt,
        Instant updatedAt,
        List<StatusHistoryEntry> statusHistory
) {

    public record StatusHistoryEntry(
            UUID id,
            String fromStatus,
            String toStatus,
            UUID changedBy,
            Instant changedAt,
            String note
    ) {
    }
}
