package vn.dcid.dto.response;

import java.time.Instant;
import java.util.UUID;

public record AppointmentDTO(
        UUID id,
        UUID applicationId,
        UUID citizenId,
        UUID officerId,
        Instant scheduledAt,
        Integer durationMinutes,
        String location,
        String status,
        String notes,
        Instant createdAt,
        Instant updatedAt
) {
}
