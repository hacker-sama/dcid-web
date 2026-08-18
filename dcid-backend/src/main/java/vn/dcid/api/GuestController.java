package vn.dcid.api;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.dcid.common.ApiResponse;
import vn.dcid.dto.request.GuestQueryRequest;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.dto.response.GuestDocumentDTO;
import vn.dcid.dto.response.GuestSessionResponse;
import vn.dcid.service.GuestService;

import java.util.UUID;

@RestController
@RequestMapping("/api/public/sessions")
public class GuestController {

    private final GuestService guestService;

    public GuestController(GuestService guestService) {
        this.guestService = guestService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<GuestSessionResponse>> createSession(HttpServletRequest request) {
        String clientIp = request.getRemoteAddr();
        GuestSessionResponse session = guestService.createSession(clientIp);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.of(session));
    }

    @PostMapping(value = "/{sessionId}/documents", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<GuestDocumentDTO>> uploadDocument(
            @PathVariable("sessionId") UUID sessionId,
            @RequestHeader(value = "X-Session-Token", required = false) String sessionToken,
            @RequestParam("file") MultipartFile file) {
        GuestDocumentDTO doc = guestService.uploadDocument(sessionId, sessionToken, file);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.of(doc));
    }

    @GetMapping("/{sessionId}/documents/{documentId}/status")
    public ResponseEntity<ApiResponse<GuestDocumentDTO>> getDocumentStatus(
            @PathVariable("sessionId") UUID sessionId,
            @PathVariable("documentId") UUID documentId,
            @RequestHeader(value = "X-Session-Token", required = false) String sessionToken) {
        GuestDocumentDTO status = guestService.getDocumentStatus(sessionId, documentId, sessionToken);
        return ResponseEntity.ok(ApiResponse.of(status));
    }

    @PostMapping("/{sessionId}/query")
    public ResponseEntity<ApiResponse<AnswerDTO>> querySession(
            @PathVariable("sessionId") UUID sessionId,
            @RequestHeader(value = "X-Session-Token", required = false) String sessionToken,
            @Valid @RequestBody GuestQueryRequest request) {
        AnswerDTO answer = guestService.querySession(sessionId, sessionToken, request.question());
        return ResponseEntity.ok(ApiResponse.of(answer));
    }

    @DeleteMapping("/{sessionId}")
    public ResponseEntity<ApiResponse<Void>> terminateSession(
            @PathVariable("sessionId") UUID sessionId,
            @RequestHeader(value = "X-Session-Token", required = false) String sessionToken) {
        guestService.terminateSession(sessionId, sessionToken);
        return ResponseEntity.ok(ApiResponse.of(null));
    }
}
