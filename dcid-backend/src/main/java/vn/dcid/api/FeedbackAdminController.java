package vn.dcid.api;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.QueryLog;
import vn.dcid.domain.entity.User;
import vn.dcid.dto.response.FeedbackAdminDTO;
import vn.dcid.repository.QueryLogRepository;
import vn.dcid.repository.UserRepository;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/feedbacks")
@PreAuthorize("hasRole('ADMIN')")
public class FeedbackAdminController {

    private final QueryLogRepository queryLogRepository;
    private final UserRepository userRepository;

    public FeedbackAdminController(QueryLogRepository queryLogRepository, UserRepository userRepository) {
        this.queryLogRepository = queryLogRepository;
        this.userRepository = userRepository;
    }

    /**
     * Danh sách phản hồi (helpful / not helpful) từ người dùng (ADMIN only).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<FeedbackAdminDTO>>> getFeedbacks(
            @RequestParam(required = false) Short feedback,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        var pageable = PageRequest.of(page, Math.min(size, 100));
        Page<QueryLog> logPage = queryLogRepository.findFeedbacks(feedback, pageable);

        List<UUID> actorIds = logPage.getContent().stream()
                .map(QueryLog::getActorId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();

        Map<UUID, String> userMap = userRepository.findAllById(actorIds).stream()
                .collect(Collectors.toMap(User::getId, User::getUsername));

        List<FeedbackAdminDTO> dtos = logPage.getContent().stream()
                .map(log -> new FeedbackAdminDTO(
                        log.getId(),
                        log.getActorId(),
                        log.getActorId() != null ? userMap.getOrDefault(log.getActorId(), "Unknown") : "Guest",
                        log.getQuestion(),
                        log.getAnswerPreview(),
                        log.getConfidence(),
                        log.getLocked(),
                        log.getFeedback(),
                        log.getFeedbackNote(),
                        log.getFeedbackAt(),
                        log.getCreatedAt()
                ))
                .toList();

        return ResponseEntity.ok(ApiResponse.of(
                PagedResponse.of(dtos, logPage.getNumber(), logPage.getSize(), logPage.getTotalElements())
        ));
    }
}
