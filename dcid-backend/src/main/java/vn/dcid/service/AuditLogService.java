package vn.dcid.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import vn.dcid.domain.entity.AuditLog;
import vn.dcid.repository.AuditLogRepository;

import java.util.UUID;

@Service
public class AuditLogService {

    private static final Logger log = LoggerFactory.getLogger(AuditLogService.class);

    private final AuditLogRepository auditLogRepository;

    public AuditLogService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @Async
    public void log(UUID actorId, String action, String resourceType, UUID resourceId,
                    String ipAddress, String detail) {
        // TODO: Implement audit log creation
        try {
            AuditLog auditLog = new AuditLog();
            auditLog.setActorId(actorId);
            auditLog.setAction(action);
            auditLog.setResourceType(resourceType);
            auditLog.setResourceId(resourceId);
            auditLog.setIpAddress(ipAddress);
            auditLog.setDetail(detail);

            auditLogRepository.save(auditLog);
        } catch (Exception e) {
            log.error("Failed to save audit log: action={}, resourceType={}, resourceId={}",
                    action, resourceType, resourceId, e);
        }
    }
}
