package vn.dcid.dto.response;

import java.time.Instant;
import java.util.UUID;

public record NotificationDTO(
        UUID id,
        UUID userId,
        String type,
        String title,
        String message,
        UUID relatedApplicationId,
        Boolean isRead,
        Instant createdAt,
        Instant readAt
) {
}
