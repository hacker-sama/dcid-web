package vn.dcid.api;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import vn.dcid.common.ApiResponse;
import vn.dcid.dto.request.QueryRequest;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.dto.response.CreateSessionResponse;
import vn.dcid.dto.response.GuestDocumentDTO;
import vn.dcid.dto.response.GuestSessionDTO;
import vn.dcid.service.GuestSessionService;

import java.util.UUID;

/** REST API cho phiên hỏi đáp tài liệu tạm thời công khai (Phân hệ B). Không yêu cầu JWT. */
@RestController
@RequestMapping("/api/public/sessions")
public class PublicSessionController {

    private static final String SESSION_TOKEN_HEADER = "X-Session-Token";
    private final GuestSessionService sessionService;

    public PublicSessionController(GuestSessionService sessionService) {
        this.sessionService = sessionService;
    }

    /** Khách mở một phiên làm việc tạm thời mới. */
    @PostMapping
    public ResponseEntity<ApiResponse<CreateSessionResponse>> createSession(HttpServletRequest request) {
        String clientIp = request.getRemoteAddr();
        CreateSessionResponse response = sessionService.createSession(clientIp);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.of(response));
    }

    /** Lấy thông tin chi tiết phiên và danh sách file tạm. */
    @GetMapping("/{sessionId}")
    public ResponseEntity<ApiResponse<GuestSessionDTO>> getSessionDetail(
            @PathVariable UUID sessionId,
            @RequestHeader(value = SESSION_TOKEN_HEADER, required = true) String token) {
        GuestSessionDTO detail = sessionService.getSessionDetail(sessionId, token);
        return ResponseEntity.ok(ApiResponse.of(detail));
    }

    /** Upload tài liệu tạm (PDF) vào phiên công khai. */
    @PostMapping(value = "/{sessionId}/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<GuestDocumentDTO>> uploadDocument(
            @PathVariable UUID sessionId,
            @RequestHeader(value = SESSION_TOKEN_HEADER, required = true) String token,
            @RequestParam("file") MultipartFile file) {
        GuestDocumentDTO uploaded = sessionService.uploadDocument(sessionId, token, file);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.of(uploaded));
    }

    /** Lấy trạng thái xử lý AI của tài liệu tạm. */
    @GetMapping("/{sessionId}/documents/{documentId}/status")
    public ResponseEntity<ApiResponse<GuestDocumentDTO>> getDocumentStatus(
            @PathVariable UUID sessionId,
            @PathVariable UUID documentId,
            @RequestHeader(value = SESSION_TOKEN_HEADER, required = true) String token) {
        GuestDocumentDTO status = sessionService.getDocumentStatus(sessionId, documentId, token);
        return ResponseEntity.ok(ApiResponse.of(status));
    }

    /** Hỏi đáp RAG trong phạm vi tài liệu thuộc phiên. */
    @PostMapping("/{sessionId}/query")
    public ResponseEntity<ApiResponse<AnswerDTO>> askQuestion(
            @PathVariable UUID sessionId,
            @RequestHeader(value = SESSION_TOKEN_HEADER, required = true) String token,
            @Valid @RequestBody QueryRequest request) {
        AnswerDTO answer = sessionService.askQuestion(sessionId, token, request);
        return ResponseEntity.ok(ApiResponse.of(answer));
    }

    /** Khách chủ động hủy phiên làm việc. */
    @DeleteMapping("/{sessionId}")
    public ResponseEntity<ApiResponse<Void>> deleteSession(
            @PathVariable UUID sessionId,
            @RequestHeader(value = SESSION_TOKEN_HEADER, required = true) String token) {
        sessionService.deleteSession(sessionId, token);
        return ResponseEntity.ok(ApiResponse.of(null));
    }
}
