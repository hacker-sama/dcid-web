package vn.dcid.dto.response;

import java.time.Instant;
import java.util.UUID;

public record GuestSessionResponse(
        UUID sessionId,
        String sessionToken,
        Instant expiresAt
) {}
