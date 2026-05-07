package vn.dcid.api.officer;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.AuditLog;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/audit-logs")
public class AuditLogController {

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<AuditLog>>> getAuditLogs(Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get audit logs");
    }

    @GetMapping("/resource/{resourceType}/{resourceId}")
    public ResponseEntity<ApiResponse<List<AuditLog>>> getAuditLogsForResource(
            @PathVariable String resourceType,
            @PathVariable UUID resourceId) {
        throw new UnsupportedOperationException("TODO: Implement get audit logs for resource");
    }

    @GetMapping("/actor/{actorId}")
    public ResponseEntity<ApiResponse<List<AuditLog>>> getAuditLogsForActor(@PathVariable UUID actorId) {
        throw new UnsupportedOperationException("TODO: Implement get audit logs for actor");
    }
}
