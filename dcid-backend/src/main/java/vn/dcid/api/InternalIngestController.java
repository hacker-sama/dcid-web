package vn.dcid.api;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.ai.AiClientConfig;
import vn.dcid.ai.AiProperties;
import vn.dcid.common.ApiResponse;
import vn.dcid.dto.request.IngestCallbackRequest;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.service.IngestService;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * Endpoint nội bộ cho dcid-ai (API-CONTRACT.md §1.2). Không dùng JWT —
 * bảo vệ bằng shared secret X-Internal-Token (so sánh constant-time).
 */
@RestController
@RequestMapping("/api/internal")
public class InternalIngestController {

    private final IngestService ingestService;
    private final AiProperties aiProperties;

    public InternalIngestController(IngestService ingestService, AiProperties aiProperties) {
        this.ingestService = ingestService;
        this.aiProperties = aiProperties;
    }

    @PostMapping("/ingest-callback")
    public ResponseEntity<ApiResponse<Void>> ingestCallback(
            @RequestHeader(value = AiClientConfig.INTERNAL_TOKEN_HEADER, required = false) String token,
            @Valid @RequestBody IngestCallbackRequest request) {
        verifyToken(token);
        ingestService.handleCallback(request);
        return ResponseEntity.ok(ApiResponse.of(null));
    }

    private void verifyToken(String token) {
        String expected = aiProperties.internalToken();
        boolean valid = token != null && expected != null && MessageDigest.isEqual(
                token.getBytes(StandardCharsets.UTF_8), expected.getBytes(StandardCharsets.UTF_8));
        if (!valid) {
            throw new ForbiddenException("Internal token không hợp lệ.");
        }
    }
}
