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
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PageRequest;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.DocumentVersion;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.dto.request.CreateDocumentRequest;
import vn.dcid.dto.request.CreateVersionRequest;
import vn.dcid.dto.response.DocumentDTO;
import vn.dcid.dto.response.DocumentDetailDTO;
import vn.dcid.dto.response.DocumentPageDTO;
import vn.dcid.dto.response.DocumentVersionDTO;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.security.SecurityContextHelper;
import vn.dcid.security.UserPrincipal;
import vn.dcid.service.DocumentService;

import java.util.List;
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

    /** QA/Admin: upload phiên bản mới của tài liệu (multipart). */
    @PostMapping(value = "/{id}/versions", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('QA_ADMIN','ADMIN')")
    public ResponseEntity<ApiResponse<DocumentVersionDTO>> uploadVersion(
            @PathVariable UUID id,
            @Valid @ModelAttribute CreateVersionRequest request) {
        DocumentVersionDTO created = documentService.createNewVersion(id, request, currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.of(created));
    }

    /** QA/Admin: phát hành phiên bản (ACTIVE). */
    @PostMapping("/{id}/versions/{versionId}/publish")
    @PreAuthorize("hasAnyRole('QA_ADMIN','ADMIN')")
    public ResponseEntity<ApiResponse<DocumentVersionDTO>> publishVersion(
            @PathVariable UUID id,
            @PathVariable UUID versionId) {
        DocumentVersionDTO version = documentService.publishVersion(id, versionId, currentUserId());
        return ResponseEntity.ok(ApiResponse.of(version));
    }

    /** QA/Admin: đánh dấu lỗi thời (OBSOLETE) phiên bản. */
    @PostMapping("/{id}/versions/{versionId}/obsolete")
    @PreAuthorize("hasAnyRole('QA_ADMIN','ADMIN')")
    public ResponseEntity<ApiResponse<DocumentVersionDTO>> obsoleteVersion(
            @PathVariable UUID id,
            @PathVariable UUID versionId) {
        DocumentVersionDTO version = documentService.obsoleteVersion(id, versionId, currentUserId());
        return ResponseEntity.ok(ApiResponse.of(version));
    }

    /** Danh sách tài liệu (phân trang + lọc RBAC theo min_role). */
    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<DocumentDTO>>> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort) {
        return ResponseEntity.ok(ApiResponse.of(documentService.list(PageRequest.of(page, size, sort), currentRole())));
    }

    /** Chi tiết tài liệu + danh sách version (lọc RBAC). */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DocumentDetailDTO>> detail(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.of(documentService.getDetail(id, currentRole())));
    }

    /** Danh sách trang + OCR text của version (lọc RBAC). */
    @GetMapping("/{id}/versions/{versionId}/pages")
    public ResponseEntity<ApiResponse<List<DocumentPageDTO>>> getVersionPages(
            @PathVariable UUID id, @PathVariable UUID versionId) {
        return ResponseEntity.ok(ApiResponse.of(documentService.getVersionPages(id, versionId, currentRole())));
    }

    /** Tải / Xem file PDF gốc của version (lọc RBAC). */
    @GetMapping("/{id}/versions/{versionId}/download")
    public ResponseEntity<Resource> downloadVersion(
            @PathVariable UUID id, @PathVariable UUID versionId) {
        DocumentVersion version = documentService.getVersionEntity(id, versionId);
        InputStreamResource resource = new InputStreamResource(
                documentService.downloadVersionFile(id, versionId, currentRole()));
        String filename = version.getOriginalFilename() != null ? version.getOriginalFilename() : "document.pdf";
        String contentType = version.getContentType() != null ? version.getContentType() : "application/pdf";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType(contentType))
                .body(resource);
    }

    /** Xóa hoàn toàn tài liệu + các phiên bản (QA_ADMIN / ADMIN). */
    @org.springframework.web.bind.annotation.DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('QA_ADMIN','ADMIN')")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable UUID id) {
        documentService.deleteDocument(id, currentUserId());
        return ResponseEntity.ok(ApiResponse.of(null));
    }

    private UUID currentUserId() {
        String id = SecurityContextHelper.getCurrentUserId();
        if (id == null) {
            throw new ForbiddenException("Chưa xác thực.");
        }
        return UUID.fromString(id);
    }

    private UserRole currentRole() {
        UserPrincipal principal = SecurityContextHelper.getCurrentUser();
        if (principal == null || principal.role() == null) {
            return null;
        }
        return UserRole.valueOf(principal.role());
    }
}

