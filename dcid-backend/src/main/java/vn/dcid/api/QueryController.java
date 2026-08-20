package vn.dcid.api;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import vn.dcid.common.ApiResponse;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.dto.request.QueryRequest;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.dto.response.VisionJobDTO;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.security.SecurityContextHelper;
import vn.dcid.security.UserPrincipal;
import vn.dcid.service.QueryService;
import vn.dcid.service.VisionJobService;

import java.io.IOException;
import java.util.UUID;

/** Hỏi–đáp RAG cho mọi vai đã đăng nhập (API-CONTRACT.md §2.1/§2.3). */
@RestController
@RequestMapping("/api/query")
public class QueryController {

    private final QueryService queryService;
    private final VisionJobService visionJobService;

    public QueryController(QueryService queryService, VisionJobService visionJobService) {
        this.queryService = queryService;
        this.visionJobService = visionJobService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AnswerDTO>> ask(@Valid @RequestBody QueryRequest request) {
        UserPrincipal principal = SecurityContextHelper.getCurrentUser();
        if (principal == null) {
            throw new ForbiddenException("Chưa xác thực.");
        }
        AnswerDTO answer = queryService.ask(
                request,
                UUID.fromString(principal.userId()),
                UserRole.valueOf(principal.role()));
        return ResponseEntity.ok(ApiResponse.of(answer));
    }

    @PostMapping(value = "/vision", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<AnswerDTO>> askWithVision(
            @org.springframework.web.bind.annotation.RequestParam("question") String question,
            @org.springframework.web.bind.annotation.RequestParam(value = "machineCode", required = false) String machineCode,
            @org.springframework.web.bind.annotation.RequestParam(value = "reasoningMode", defaultValue = "false") boolean reasoningMode,
            @org.springframework.web.bind.annotation.RequestParam("file") org.springframework.web.multipart.MultipartFile file) {
        UserPrincipal principal = SecurityContextHelper.getCurrentUser();
        if (principal == null) {
            throw new ForbiddenException("Chưa xác thực.");
        }
        AnswerDTO answer = queryService.askWithVision(
                question, machineCode, reasoningMode, file,
                UUID.fromString(principal.userId()),
                UserRole.valueOf(principal.role()));
        return ResponseEntity.ok(ApiResponse.of(answer));
    }

    @PostMapping(value = "/vision/jobs", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<VisionJobDTO>> createVisionJob(
            @org.springframework.web.bind.annotation.RequestParam("question") String question,
            @org.springframework.web.bind.annotation.RequestParam(value = "machineCode", required = false) String machineCode,
            @org.springframework.web.bind.annotation.RequestParam(value = "reasoningMode", defaultValue = "false") boolean reasoningMode,
            @org.springframework.web.bind.annotation.RequestParam("file") org.springframework.web.multipart.MultipartFile file)
            throws IOException {
        UserPrincipal principal = SecurityContextHelper.getCurrentUser();
        if (principal == null) {
            throw new ForbiddenException("Chưa xác thực.");
        }
        VisionJobDTO job = visionJobService.submit(
                question,
                machineCode,
                reasoningMode,
                file.getBytes(),
                file.getOriginalFilename(),
                file.getContentType(),
                UUID.fromString(principal.userId()),
                UserRole.valueOf(principal.role()));
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(ApiResponse.of(job));
    }

    @GetMapping("/vision/jobs/{jobId}")
    public ResponseEntity<ApiResponse<VisionJobDTO>> getVisionJob(@PathVariable UUID jobId) {
        UserPrincipal principal = SecurityContextHelper.getCurrentUser();
        if (principal == null) {
            throw new ForbiddenException("Chưa xác thực.");
        }
        return ResponseEntity.ok(ApiResponse.of(
                visionJobService.get(jobId, UUID.fromString(principal.userId()))));
    }

    @GetMapping(value = "/vision/jobs/{jobId}/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamVisionJob(@PathVariable UUID jobId) {
        UserPrincipal principal = SecurityContextHelper.getCurrentUser();
        if (principal == null) {
            throw new ForbiddenException("Chưa xác thực.");
        }
        return visionJobService.events(jobId, UUID.fromString(principal.userId()));
    }

    @PostMapping(value = "/stream", produces = org.springframework.http.MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter askStreaming(@Valid @RequestBody QueryRequest request) {
        UserPrincipal principal = SecurityContextHelper.getCurrentUser();
        if (principal == null) {
            throw new ForbiddenException("Chưa xác thực.");
        }
        return queryService.askStreaming(
                request,
                UUID.fromString(principal.userId()),
                UserRole.valueOf(principal.role()));
    }
}
