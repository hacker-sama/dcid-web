package vn.dcid.dto.response;

import vn.dcid.domain.entity.AuditLog;

import java.time.Instant;
import java.util.UUID;

/** DTO trả về client cho mỗi bản ghi audit log. */
public record AuditLogDTO(
        UUID id,
        UUID actorId,
        String action,
        String resourceType,
        UUID resourceId,
        String ipAddress,
        String detail,
        Instant createdAt
) {
    public static AuditLogDTO from(AuditLog log) {
        return new AuditLogDTO(
                log.getId(),
                log.getActorId(),
                log.getAction(),
                log.getResourceType(),
                log.getResourceId(),
                log.getIpAddress(),
                log.getDetail(),
                log.getCreatedAt()
        );
    }
}
