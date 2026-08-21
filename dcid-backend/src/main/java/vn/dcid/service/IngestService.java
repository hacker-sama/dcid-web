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
    private final vn.dcid.repository.GuestDocumentRepository guestDocumentRepository;
    private final AuditLogService auditLogService;
    private final SimpMessagingTemplate messagingTemplate;

    public IngestService(DocumentVersionRepository versionRepository,
                         DocumentPageRepository pageRepository,
                         vn.dcid.repository.GuestDocumentRepository guestDocumentRepository,
                         AuditLogService auditLogService,
                         SimpMessagingTemplate messagingTemplate) {
        this.versionRepository = versionRepository;
        this.pageRepository = pageRepository;
        this.guestDocumentRepository = guestDocumentRepository;
        this.auditLogService = auditLogService;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional
    public void handleCallback(IngestCallbackRequest req) {
        var optVersion = versionRepository.findById(req.versionId());
        if (optVersion.isEmpty()) {
            // Check if this is a GuestDocument
            var optGuestDoc = guestDocumentRepository.findById(req.versionId());
            if (optGuestDoc.isPresent()) {
                handleGuestCallback(optGuestDoc.get(), req);
                return;
            }
            throw new NotFoundException("DocumentVersion or GuestDocument", req.versionId().toString());
        }

        DocumentVersion version = optVersion.get();

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
        List<DocumentPage> pageEntities = new java.util.ArrayList<>(pages.size());
        for (IngestCallbackRequest.PageInfo p : pages) {
            DocumentPage page = new DocumentPage();
            page.setVersionId(version.getId());
            page.setPageNo(p.pageNo());
            page.setImageKey(p.imageKey());
            page.setWidth(p.width());
            page.setHeight(p.height());
            // Strip null bytes (\x00) — PaddleOCR đôi khi trả về null byte
            // trong kết quả OCR; PostgreSQL UTF8 reject toàn bộ batch nếu có.
            page.setOcrText(p.ocrText() != null ? p.ocrText().replace("\u0000", "") : null);
            pageEntities.add(page);
        }
        pageRepository.saveAll(pageEntities); // batch INSERT — tránh N+1 khi có 200+ trang

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

    private void handleGuestCallback(vn.dcid.domain.entity.GuestDocument guestDoc, IngestCallbackRequest req) {
        if ("FAILED".equals(req.status())) {
            guestDoc.setStatus(vn.dcid.domain.enums.GuestDocumentStatus.FAILED);
            guestDoc.setErrorMessage(req.error());
            guestDocumentRepository.save(guestDoc);
            log.warn("Ingest FAILED cho guest doc {}: {}", guestDoc.getId(), req.error());
            messagingTemplate.convertAndSend("/topic/ingest/" + guestDoc.getId(),
                    new IngestProgressMessage(guestDoc.getId(), "FAILED", 0, req.error()));
            return;
        }

        List<IngestCallbackRequest.PageInfo> pages = req.pages() != null ? req.pages() : List.of();
        guestDoc.setStatus(vn.dcid.domain.enums.GuestDocumentStatus.READY);
        guestDoc.setPageCount(req.pageCount() != null ? req.pageCount() : pages.size());
        guestDoc.setErrorMessage(null);
        guestDocumentRepository.save(guestDoc);

        log.info("Ingest READY cho guest doc {} ({} trang)", guestDoc.getId(), guestDoc.getPageCount());
        messagingTemplate.convertAndSend("/topic/ingest/" + guestDoc.getId(),
                new IngestProgressMessage(guestDoc.getId(), "READY", 100, "Xử lý thành công"));
    }
}
