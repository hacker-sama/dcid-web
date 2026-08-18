package vn.dcid.api;

import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.QueryLog;
import vn.dcid.domain.entity.User;
import vn.dcid.dto.response.QueryHistoryDTO;
import vn.dcid.repository.QueryLogRepository;
import vn.dcid.service.UserService;

import java.util.List;

@RestController
@RequestMapping("/api/query/history")
public class QueryHistoryController {

    private final QueryLogRepository queryLogRepository;
    private final UserService userService;

    public QueryHistoryController(QueryLogRepository queryLogRepository, UserService userService) {
        this.queryLogRepository = queryLogRepository;
        this.userService = userService;
    }

    /** Lịch sử câu hỏi của user đang đăng nhập. Phân trang, sắp xếp mới nhất trước. */
    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<QueryHistoryDTO>>> getHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        User user = userService.getCurrentUser();
        var pageable = PageRequest.of(page, Math.min(size, 50));
        var logPage = queryLogRepository.findByActorIdOrderByCreatedAtDesc(user.getId(), pageable);
        List<QueryHistoryDTO> dtos = logPage.getContent().stream()
                .map(this::toDto)
                .toList();
        var paged = PagedResponse.of(dtos, logPage.getNumber(), logPage.getSize(), logPage.getTotalElements());
        return ResponseEntity.ok(ApiResponse.of(paged));
    }

    private QueryHistoryDTO toDto(QueryLog log) {
        return new QueryHistoryDTO(
                log.getId(),
                log.getQuestion(),
                log.getAnswerPreview(),
                log.getConfidence(),
                log.getLocked(),
                log.getNumericRuleHit(),
                log.getLatencyMs(),
                log.getCreatedAt(),
                log.getFeedback(),
                log.getFeedbackNote(),
                log.getFeedbackAt()
        );
    }
}
