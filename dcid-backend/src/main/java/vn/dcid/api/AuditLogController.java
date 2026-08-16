package vn.dcid.api;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.AuditLog;
import vn.dcid.dto.response.AuditLogDTO;
import vn.dcid.repository.AuditLogRepository;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

/**
 * GET /api/admin/audit-logs — Nhật ký kiểm toán hệ thống (ADMIN only).
 *
 * <p>Query params:
 * <ul>
 *   <li>{@code actorId}   — lọc theo người thực hiện (UUID, tuỳ chọn)</li>
 *   <li>{@code action}    — lọc theo loại hành động (DOCUMENT_UPLOAD, USER_LOGIN…, tuỳ chọn)</li>
 *   <li>{@code days}      — khoảng thời gian nhìn lại tính từ hiện tại (mặc định 30 ngày)</li>
 *   <li>{@code page/size} — phân trang</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/admin/audit-logs")
@PreAuthorize("hasRole('ADMIN')")
public class AuditLogController {

    private final AuditLogRepository auditLogRepository;

    public AuditLogController(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<AuditLogDTO>>> list(
            @RequestParam(required = false) UUID actorId,
            @RequestParam(required = false) String action,
            @RequestParam(defaultValue = "30") int days,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {

        PageRequest pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Instant since = Instant.now().minus(days, ChronoUnit.DAYS);

        Page<AuditLog> result;
        if (actorId != null) {
            result = auditLogRepository.findByActorIdOrderByCreatedAtDesc(actorId, pageable);
        } else if (action != null && !action.isBlank()) {
            result = auditLogRepository.findByActionAndCreatedAtAfter(action, since, pageable);
        } else {
            result = auditLogRepository.findByCreatedAtAfter(since, pageable);
        }

        List<AuditLogDTO> items = result.getContent().stream().map(AuditLogDTO::from).toList();
        return ResponseEntity.ok(ApiResponse.of(
                PagedResponse.of(items, result.getNumber(), result.getSize(), result.getTotalElements())));
    }
}
