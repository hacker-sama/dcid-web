package vn.dcid.api;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PageRequest;
import vn.dcid.common.PagedResponse;
import vn.dcid.dto.request.CreateDocumentRequest;
import vn.dcid.dto.response.DocumentDTO;
import vn.dcid.dto.response.DocumentDetailDTO;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.security.SecurityContextHelper;
import vn.dcid.service.DocumentService;

import java.util.UUID;

@RestController
@RequestMapping("/api/documents")
public class DocumentController {

    private final DocumentService documentService;

    public DocumentController(DocumentService documentService) {
        this.documentService = documentService;
    }

    /** QA/Admin: tạo tài liệu + upload version đầu tiên (multipart). */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('QA_ADMIN','ADMIN')")
    public ResponseEntity<ApiResponse<DocumentDetailDTO>> upload(
            @Valid @ModelAttribute CreateDocumentRequest request) {
        DocumentDetailDTO created = documentService.createDocument(request, currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.of(created));
    }

    /** Danh sách tài liệu (phân trang). */
    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<DocumentDTO>>> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.of(documentService.list(PageRequest.of(page, size))));
    }

    /** Chi tiết tài liệu + danh sách version. */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DocumentDetailDTO>> detail(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.of(documentService.getDetail(id)));
    }

    private UUID currentUserId() {
        String id = SecurityContextHelper.getCurrentUserId();
        if (id == null) {
            throw new ForbiddenException("Chưa xác thực.");
        }
        return UUID.fromString(id);
    }
}
