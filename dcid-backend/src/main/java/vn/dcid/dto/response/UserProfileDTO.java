package vn.dcid.dto.response;

import java.time.Instant;
import java.util.UUID;

public record UserProfileDTO(
        UUID id,
        String email,
        String role,
        Boolean isActive,
        Instant createdAt,
        Instant updatedAt
) {
}
