package vn.dcid.api;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.domain.entity.QueryLog;
import vn.dcid.domain.entity.User;
import vn.dcid.dto.request.FeedbackRequest;
import vn.dcid.exception.NotFoundException;
import vn.dcid.repository.QueryLogRepository;
import vn.dcid.service.UserService;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/api/query")
public class FeedbackController {

    private final QueryLogRepository queryLogRepository;
    private final UserService userService;

    public FeedbackController(QueryLogRepository queryLogRepository, UserService userService) {
        this.queryLogRepository = queryLogRepository;
        this.userService = userService;
    }

    /**
     * Gửi phản hồi (helpful/not helpful) cho một câu trả lời AI.
     * Chỉ actor gốc mới được feedback. Chỉ ghi một lần (idempotent update).
     */
    @PostMapping("/{id}/feedback")
    public ResponseEntity<ApiResponse<Void>> submitFeedback(
            @PathVariable UUID id,
            @Valid @RequestBody FeedbackRequest request) {
        User user = userService.getCurrentUser();
        QueryLog log = queryLogRepository.findByIdAndActorId(id, user.getId())
                .orElseThrow(() -> new NotFoundException("QueryLog", id.toString()));
        log.setFeedback(Boolean.TRUE.equals(request.helpful()) ? (short) 1 : (short) -1);
        log.setFeedbackNote(request.note());
        log.setFeedbackAt(Instant.now());
        queryLogRepository.save(log);
        return ResponseEntity.ok(ApiResponse.of(null));
    }
}
