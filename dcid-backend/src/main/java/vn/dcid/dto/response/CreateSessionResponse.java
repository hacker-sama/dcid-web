package vn.dcid.dto.response;

import java.time.Instant;
import java.util.UUID;

public record CreateSessionResponse(
        UUID sessionId,
        String sessionToken,
        Instant expiresAt
) {
}
