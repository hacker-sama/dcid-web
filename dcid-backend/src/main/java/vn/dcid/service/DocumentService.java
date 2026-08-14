package vn.dcid.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import vn.dcid.ai.AiPipelineClient;
import vn.dcid.ai.dto.AiIngestRequest;
import vn.dcid.common.PageRequest;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.Document;
import vn.dcid.domain.entity.DocumentVersion;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.domain.enums.VersionStatus;
import vn.dcid.dto.request.CreateDocumentRequest;
import vn.dcid.dto.request.CreateVersionRequest;
import vn.dcid.dto.response.DocumentDTO;
import vn.dcid.dto.response.DocumentDetailDTO;
import vn.dcid.dto.response.DocumentPageDTO;
import vn.dcid.dto.response.DocumentVersionDTO;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.exception.NotFoundException;
import vn.dcid.exception.PolicyViolationException;
import vn.dcid.repository.DocumentPageRepository;
import vn.dcid.repository.DocumentRepository;
import vn.dcid.repository.DocumentVersionRepository;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
public class DocumentService {

    private static final Logger log = LoggerFactory.getLogger(DocumentService.class);

    private final DocumentRepository documentRepository;
    private final DocumentVersionRepository versionRepository;
    private final DocumentPageRepository pageRepository;
    private final MinioService minioService;
    private final AuditLogService auditLogService;
    private final AiPipelineClient aiPipelineClient;

    public DocumentService(DocumentRepository documentRepository,
                           DocumentVersionRepository versionRepository,
                           DocumentPageRepository pageRepository,
                           MinioService minioService,
                           AuditLogService auditLogService,
                           AiPipelineClient aiPipelineClient) {
        this.documentRepository = documentRepository;
        this.versionRepository = versionRepository;
        this.pageRepository = pageRepository;
        this.minioService = minioService;
        this.auditLogService = auditLogService;
        this.aiPipelineClient = aiPipelineClient;
    }

    /** Tạo tài liệu mới + upload version đầu tiên (PROCESSING) vào MinIO. */
    @Transactional
    public DocumentDetailDTO createDocument(CreateDocumentRequest req, UUID actorId) {
        MultipartFile file = req.getFile();
        if (file == null || file.isEmpty()) {
            throw new PolicyViolationException("File rỗng hoặc không hợp lệ.");
        }
        final byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            throw new PolicyViolationException("Không đọc được file: " + e.getMessage());
        }

        Document doc = new Document();
        doc.setTitle(req.getTitle());
        doc.setMachineCode(req.getMachineCode());
        doc.setCategory(req.getCategory());
        doc.setMinRole(req.getMinRole() != null ? req.getMinRole() : UserRole.OPERATOR);
        doc.setDescription(req.getDescription());
        doc.setCreatedBy(actorId);
        doc = documentRepository.save(doc);

        int versionNo = 1;
        String storageKey = "documents/" + doc.getId() + "/v" + versionNo + "/original.pdf";
        String contentType = file.getContentType() != null ? file.getContentType() : "application/pdf";
        minioService.upload(storageKey, new ByteArrayInputStream(bytes), bytes.length, contentType);

        DocumentVersion version = new DocumentVersion();
        version.setDocumentId(doc.getId());
        version.setVersionNo(versionNo);
        version.setStorageKey(storageKey);
        version.setOriginalFilename(file.getOriginalFilename());
        version.setContentType(contentType);
        version.setFileSize((long) bytes.length);
        version.setChecksum(sha256(bytes));
        version.setLang(req.getLang());
        version.setStatus(VersionStatus.PROCESSING);
        version.setCreatedBy(actorId);
        version = versionRepository.save(version);

        auditLogService.log(actorId, "DOCUMENT_UPLOAD", "DOCUMENT", doc.getId(), null, null);

        // Kích hoạt AI ingest (API-CONTRACT.md §1.1). AI chết → version FAILED, upload vẫn thành công.
        triggerIngest(doc, version);

        return new DocumentDetailDTO(DocumentDTO.from(doc), List.of(DocumentVersionDTO.from(version)));
    }

    /** Upload phiên bản mới (v2, v3...) của tài liệu đã có. */
    @Transactional
    public DocumentVersionDTO createNewVersion(UUID documentId, CreateVersionRequest req, UUID actorId) {
        Document doc = documentRepository.findById(documentId)
                .orElseThrow(() -> new NotFoundException("Document", documentId.toString()));

        MultipartFile file = req.getFile();
        if (file == null || file.isEmpty()) {
            throw new PolicyViolationException("File rỗng hoặc không hợp lệ.");
        }
        final byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            throw new PolicyViolationException("Không đọc được file: " + e.getMessage());
        }

        int nextVersionNo = versionRepository.findMaxVersionNo(documentId) + 1;
        String storageKey = "documents/" + doc.getId() + "/v" + nextVersionNo + "/original.pdf";
        String contentType = file.getContentType() != null ? file.getContentType() : "application/pdf";
        minioService.upload(storageKey, new ByteArrayInputStream(bytes), bytes.length, contentType);

        DocumentVersion version = new DocumentVersion();
        version.setDocumentId(doc.getId());
        version.setVersionNo(nextVersionNo);
        version.setStorageKey(storageKey);
        version.setOriginalFilename(file.getOriginalFilename());
        version.setContentType(contentType);
        version.setFileSize((long) bytes.length);
        version.setChecksum(sha256(bytes));
        version.setLang(req.getLang());
        version.setStatus(VersionStatus.PROCESSING);
        version.setCreatedBy(actorId);
        version = versionRepository.save(version);

        auditLogService.log(actorId, "DOCUMENT_VERSION_CREATE", "DOCUMENT_VERSION", version.getId(), null, null);
        triggerIngest(doc, version);

        return DocumentVersionDTO.from(version);
    }

    /** Phát hành phiên bản (ACTIVE). Phiên bản ACTIVE cũ tự động đổi thành SUPERSEDED. */
    @Transactional
    public DocumentVersionDTO publishVersion(UUID documentId, UUID versionId, UUID actorId) {
        DocumentVersion version = getVersionEntity(documentId, versionId);

        // Chuyển phiên bản ACTIVE cũ (nếu có) thành SUPERSEDED
        Optional<DocumentVersion> currentActive = versionRepository
                .findFirstByDocumentIdAndStatus(documentId, VersionStatus.ACTIVE);
        if (currentActive.isPresent() && !currentActive.get().getId().equals(versionId)) {
            DocumentVersion oldActive = currentActive.get();
            oldActive.setStatus(VersionStatus.SUPERSEDED);
            versionRepository.save(oldActive);
            log.info("Phiên bản cũ v{} (id={}) đã chuyển thành SUPERSEDED", oldActive.getVersionNo(), oldActive.getId());
        }

        version.setStatus(VersionStatus.ACTIVE);
        version = versionRepository.save(version);

        auditLogService.log(actorId, "DOCUMENT_VERSION_PUBLISH", "DOCUMENT_VERSION", versionId, null, null);
        log.info("Đã phát hành phiên bản v{} (id={}) của documentId={}", version.getVersionNo(), versionId, documentId);

        return DocumentVersionDTO.from(version);
    }

    /** Đánh dấu lỗi thời (OBSOLETE) một phiên bản tài liệu. */
    @Transactional
    public DocumentVersionDTO obsoleteVersion(UUID documentId, UUID versionId, UUID actorId) {
        DocumentVersion version = getVersionEntity(documentId, versionId);

        version.setStatus(VersionStatus.OBSOLETE);
        version = versionRepository.save(version);

        auditLogService.log(actorId, "DOCUMENT_VERSION_OBSOLETE", "DOCUMENT_VERSION", versionId, null, null);
        log.info("Đã chuyển phiên bản v{} (id={}) sang OBSOLETE", version.getVersionNo(), versionId);

        return DocumentVersionDTO.from(version);
    }

    @Transactional(readOnly = true)
    public PagedResponse<DocumentDTO> list(PageRequest pageRequest, UserRole actorRole) {
        Page<Document> page;
        if (actorRole != null) {
            List<UserRole> allowedRoles = Arrays.stream(UserRole.values())
                    .filter(r -> r.getLevel() <= actorRole.getLevel())
                    .toList();
            page = documentRepository.findByMinRoleIn(allowedRoles, pageRequest.toSpringPageRequest());
        } else {
            page = documentRepository.findAll(pageRequest.toSpringPageRequest());
        }
        List<DocumentDTO> items = page.getContent().stream().map(DocumentDTO::from).toList();
        return PagedResponse.of(items, page.getNumber(), page.getSize(), page.getTotalElements());
    }

    @Transactional(readOnly = true)
    public DocumentDetailDTO getDetail(UUID id, UserRole actorRole) {
        Document doc = documentRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Document", id.toString()));
        if (actorRole != null && doc.getMinRole().getLevel() > actorRole.getLevel()) {
            throw new ForbiddenException("Bạn không có quyền truy cập tài liệu này.");
        }
        List<DocumentVersionDTO> versions = versionRepository.findByDocumentIdOrderByVersionNoDesc(id)
                .stream().map(DocumentVersionDTO::from).toList();
        return new DocumentDetailDTO(DocumentDTO.from(doc), versions);
    }

    @Transactional(readOnly = true)
    public DocumentVersion getVersionEntity(UUID documentId, UUID versionId) {
        DocumentVersion version = versionRepository.findById(versionId)
                .orElseThrow(() -> new NotFoundException("DocumentVersion", versionId.toString()));
        if (!version.getDocumentId().equals(documentId)) {
            throw new NotFoundException("DocumentVersion", versionId.toString());
        }
        return version;
    }

    @Transactional(readOnly = true)
    public InputStream downloadVersionFile(UUID documentId, UUID versionId, UserRole actorRole) {
        Document doc = documentRepository.findById(documentId)
                .orElseThrow(() -> new NotFoundException("Document", documentId.toString()));
        if (actorRole != null && doc.getMinRole().getLevel() > actorRole.getLevel()) {
            throw new ForbiddenException("Bạn không có quyền tải file từ tài liệu này.");
        }
        DocumentVersion version = getVersionEntity(documentId, versionId);
        return minioService.download(version.getStorageKey());
    }

    @Transactional(readOnly = true)
    public List<DocumentPageDTO> getVersionPages(UUID documentId, UUID versionId, UserRole actorRole) {
        Document doc = documentRepository.findById(documentId)
                .orElseThrow(() -> new NotFoundException("Document", documentId.toString()));
        if (actorRole != null && doc.getMinRole().getLevel() > actorRole.getLevel()) {
            throw new ForbiddenException("Bạn không có quyền xem các trang của tài liệu này.");
        }
        getVersionEntity(documentId, versionId);
        return pageRepository.findByVersionIdOrderByPageNo(versionId)
                .stream().map(DocumentPageDTO::from).toList();
    }

    private void triggerIngest(Document doc, DocumentVersion version) {
        List<String> langs = version.getLang() != null && !version.getLang().isBlank()
                ? Arrays.stream(version.getLang().split(",")).map(String::trim).toList()
                : List.of("vi", "en");
        Map<String, String> metadata = new LinkedHashMap<>();
        metadata.put("title", doc.getTitle());
        if (doc.getMachineCode() != null) {
            metadata.put("machineCode", doc.getMachineCode());
        }
        metadata.put("category", doc.getCategory().name());
        metadata.put("minRole", doc.getMinRole().name());

        try {
            aiPipelineClient.ingest(new AiIngestRequest(
                    version.getId(), doc.getId(), version.getStorageKey(), langs, metadata));
        } catch (Exception e) {
            // Log kèm exception object (không chỉ getMessage()) để SLF4J in đủ stack trace +
            // cause chain — thiếu việc này từng khiến lỗi thật (HTTP/1.1 vs 2) bị che mất.
            log.error("Không gọi được AI ingest cho version {}", version.getId(), e);
            String reason = e.getCause() != null ? e.getCause().getMessage() : e.getMessage();
            version.setStatus(VersionStatus.FAILED);
            version.setErrorMessage("Không gọi được AI service: " + reason);
            versionRepository.save(version);
        }
    }

    @Transactional
    public void deleteDocument(UUID id, UUID actorId) {
        Document doc = documentRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Document", id.toString()));

        List<DocumentVersion> versions = versionRepository.findByDocumentIdOrderByVersionNoDesc(id);
        for (DocumentVersion version : versions) {
            try {
                if (version.getStorageKey() != null) {
                    minioService.delete(version.getStorageKey());
                }
            } catch (Exception e) {
                log.warn("Không thể xóa file MinIO storageKey={}: {}", version.getStorageKey(), e.getMessage());
            }

            pageRepository.deleteByVersionId(version.getId());
        }

        versionRepository.deleteAll(versions);

        try {
            aiPipelineClient.deleteDocument(id);
        } catch (Exception e) {
            log.warn("Không thể xóa vector chunks trên AI service cho docId={}: {}", id, e.getMessage());
        }

        documentRepository.delete(doc);

        auditLogService.log(actorId, "DOCUMENT_DELETE", "DOCUMENT", id, null, null);
        log.info("Đã xóa hoàn toàn documentId={} và {} versions", id, versions.size());
    }

    private static String sha256(byte[] bytes) {

        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(bytes);
            StringBuilder sb = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            return null;
        }
    }
}
