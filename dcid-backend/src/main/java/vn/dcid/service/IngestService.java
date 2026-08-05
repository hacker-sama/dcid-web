package vn.dcid.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.dcid.domain.entity.DocumentPage;
import vn.dcid.domain.entity.DocumentVersion;
import vn.dcid.domain.enums.VersionStatus;
import vn.dcid.dto.request.IngestCallbackRequest;
import vn.dcid.exception.NotFoundException;
import vn.dcid.repository.DocumentPageRepository;
import vn.dcid.repository.DocumentVersionRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import vn.dcid.dto.response.IngestProgressMessage;

import java.time.Instant;
import java.util.List;

/**
 * Xử lý ingest-callback từ dcid-ai (API-CONTRACT.md §1.2).
 * Chính sách MVP: callback READY = auto-publish (version → ACTIVE, ACTIVE cũ → SUPERSEDED).
 */
@Service
public class IngestService {

    private static final Logger log = LoggerFactory.getLogger(IngestService.class);

    private final DocumentVersionRepository versionRepository;
    private final DocumentPageRepository pageRepository;
    private final AuditLogService auditLogService;
    private final SimpMessagingTemplate messagingTemplate;

    public IngestService(DocumentVersionRepository versionRepository,
                         DocumentPageRepository pageRepository,
                         AuditLogService auditLogService,
                         SimpMessagingTemplate messagingTemplate) {
        this.versionRepository = versionRepository;
        this.pageRepository = pageRepository;
        this.auditLogService = auditLogService;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional
    public void handleCallback(IngestCallbackRequest req) {
        DocumentVersion version = versionRepository.findById(req.versionId())
                .orElseThrow(() -> new NotFoundException("DocumentVersion", req.versionId().toString()));

        if ("FAILED".equals(req.status())) {
            version.setStatus(VersionStatus.FAILED);
            version.setErrorMessage(req.error());
            versionRepository.save(version);
            log.warn("Ingest FAILED cho version {}: {}", version.getId(), req.error());
            auditLogService.log(version.getCreatedBy(), "DOCUMENT_INGEST_FAILED", "DOCUMENT_VERSION",
                    version.getId(), null, req.error());
            messagingTemplate.convertAndSend("/topic/ingest/" + version.getId(),
                    new IngestProgressMessage(version.getId(), "FAILED", 0, req.error()));
            return;
        }

        // READY: ghi lại pages (idempotent — xóa cũ trước)
        pageRepository.deleteByVersionId(version.getId());
        List<IngestCallbackRequest.PageInfo> pages = req.pages() != null ? req.pages() : List.of();
        for (IngestCallbackRequest.PageInfo p : pages) {
            DocumentPage page = new DocumentPage();
            page.setVersionId(version.getId());
            page.setPageNo(p.pageNo());
            page.setImageKey(p.imageKey());
            page.setWidth(p.width());
            page.setHeight(p.height());
            page.setOcrText(p.ocrText());
            pageRepository.save(page);
        }

        // Auto-publish: ACTIVE cũ của cùng document → SUPERSEDED
        versionRepository.findFirstByDocumentIdAndStatus(version.getDocumentId(), VersionStatus.ACTIVE)
                .filter(active -> !active.getId().equals(version.getId()))
                .ifPresent(active -> {
                    active.setStatus(VersionStatus.SUPERSEDED);
                    versionRepository.save(active);
                });

        version.setPageCount(req.pageCount() != null ? req.pageCount() : pages.size());
        version.setIngestedAt(Instant.now());
        version.setStatus(VersionStatus.ACTIVE);
        version.setErrorMessage(null);
        versionRepository.save(version);

        log.info("Ingest READY: version {} → ACTIVE ({} trang)", version.getId(), version.getPageCount());
        auditLogService.log(version.getCreatedBy(), "DOCUMENT_INGESTED", "DOCUMENT_VERSION",
                version.getId(), null, null);
        messagingTemplate.convertAndSend("/topic/ingest/" + version.getId(),
                new IngestProgressMessage(version.getId(), "READY", 100, "Xử lý thành công"));
    }
}
