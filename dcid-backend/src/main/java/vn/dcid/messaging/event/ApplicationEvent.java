package vn.dcid.messaging.event;

import java.time.Instant;
import java.util.UUID;

public record ApplicationEvent(
        String eventType,
        UUID applicationId,
        UUID applicantId,
        String status,
        Instant timestamp
) {
}
