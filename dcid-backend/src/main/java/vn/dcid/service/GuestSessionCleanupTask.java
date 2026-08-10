package vn.dcid.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import vn.dcid.ai.AiPipelineClient;
import vn.dcid.domain.entity.GuestDocument;
import vn.dcid.domain.entity.GuestSession;
import vn.dcid.domain.enums.SessionStatus;
import vn.dcid.repository.GuestDocumentRepository;
import vn.dcid.repository.GuestSessionRepository;

import java.time.Instant;
import java.util.List;

/** Tiến trình dọn dẹp định kỳ các phiên công khai hết hạn (TTL Cleanup Job). */
@Component
public class GuestSessionCleanupTask {

    private static final Logger log = LoggerFactory.getLogger(GuestSessionCleanupTask.class);

    private final GuestSessionRepository sessionRepository;
    private final GuestDocumentRepository documentRepository;
    private final MinioService minioService;
    private final AiPipelineClient aiPipelineClient;

    public GuestSessionCleanupTask(GuestSessionRepository sessionRepository,
                                  GuestDocumentRepository documentRepository,
                                  MinioService minioService,
                                  AiPipelineClient aiPipelineClient) {
        this.sessionRepository = sessionRepository;
        this.documentRepository = documentRepository;
        this.minioService = minioService;
        this.aiPipelineClient = aiPipelineClient;
    }

    @Scheduled(cron = "0 */10 * * * *")
    @Transactional
    public void cleanupExpiredSessions() {
        Instant now = Instant.now();
        List<GuestSession> expiredSessions = sessionRepository.findByExpiresAtBeforeAndDeletedAtIsNull(now);

        if (expiredSessions.isEmpty()) {
            return;
        }

        int cleanedCount = 0;
        for (GuestSession session : expiredSessions) {
            try {
                List<GuestDocument> docs = documentRepository.findBySessionId(session.getId());
                for (GuestDocument doc : docs) {
                    try {
                        minioService.delete(doc.getStorageKey());
                    } catch (Exception e) {
                        log.warn("Không thể xóa file MinIO guest doc storageKey={}: {}", doc.getStorageKey(), e.getMessage());
                    }
                }

                try {
                    aiPipelineClient.deleteGuestSessionVectors(session.getId());
                } catch (Exception e) {
                    log.warn("Không thể xóa vector Qdrant cho guest sessionId={}: {}", session.getId(), e.getMessage());
                }

                session.setStatus(SessionStatus.EXPIRED);
                session.setDeletedAt(now);
                sessionRepository.save(session);
                cleanedCount++;
            } catch (Exception e) {
                log.error("Lỗi khi tiêu hủy guest session id={}", session.getId(), e);
            }
        }

        log.info("Dọn dẹp tự động (TTL Cleanup): Đã tiêu hủy thành công {}/{} phiên ẩn danh hết hạn",
                cleanedCount, expiredSessions.size());
    }
}
