package vn.dcid.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import vn.dcid.ai.AiPipelineClient;
import vn.dcid.ai.dto.AiCitation;
import vn.dcid.ai.dto.AiIngestRequest;
import vn.dcid.ai.dto.AiQueryRequest;
import vn.dcid.ai.dto.AiQueryResponse;
import vn.dcid.domain.entity.GuestDocument;
import vn.dcid.domain.entity.GuestSession;
import vn.dcid.domain.entity.QueryLog;
import vn.dcid.domain.enums.GuestDocumentStatus;
import vn.dcid.domain.enums.GuestSessionStatus;
import vn.dcid.domain.enums.QueryScope;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.dto.response.GuestDocumentDTO;
import vn.dcid.dto.response.GuestSessionResponse;
import vn.dcid.exception.AppException;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.exception.NotFoundException;
import vn.dcid.repository.GuestDocumentRepository;
import vn.dcid.repository.GuestSessionRepository;
import vn.dcid.repository.QueryLogRepository;

import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

@Service
public class GuestService {

    private static final Logger log = LoggerFactory.getLogger(GuestService.class);
    private static final Duration SESSION_TTL = Duration.ofHours(2);
    private static final long MAX_FILE_SIZE = 25 * 1024 * 1024L; // 25 MB

    private final GuestSessionRepository sessionRepository;
    private final GuestDocumentRepository documentRepository;
    private final QueryLogRepository queryLogRepository;
    private final AiPipelineClient aiPipelineClient;
    private final MinioService minioService;
    private final SecureRandom secureRandom = new SecureRandom();

    public GuestService(GuestSessionRepository sessionRepository,
                        GuestDocumentRepository documentRepository,
                        QueryLogRepository queryLogRepository,
                        AiPipelineClient aiPipelineClient,
                        MinioService minioService) {
        this.sessionRepository = sessionRepository;
        this.documentRepository = documentRepository;
        this.queryLogRepository = queryLogRepository;
        this.aiPipelineClient = aiPipelineClient;
        this.minioService = minioService;
    }

    @Transactional
    public GuestSessionResponse createSession(String clientIp) {
        String rawToken = generateSecureToken();
        String tokenHash = hashToken(rawToken);

        Instant now = Instant.now();
        Instant expiresAt = now.plus(SESSION_TTL);

        GuestSession session = new GuestSession();
        session.setSessionTokenHash(tokenHash);
        session.setStatus(GuestSessionStatus.ACTIVE);
        session.setCreatedAt(now);
        session.setExpiresAt(expiresAt);
        session.setLastAccessedAt(now);
        if (clientIp != null) {
            session.setIpHash(hashToken(clientIp));
        }

        GuestSession saved = sessionRepository.save(session);
        log.info("Khởi tạo phiên tạm ẩn danh: id={}, expiresAt={}", saved.getId(), expiresAt);
        return new GuestSessionResponse(saved.getId(), rawToken, expiresAt);
    }

    @Transactional
    public GuestDocumentDTO uploadDocument(UUID sessionId, String rawToken, MultipartFile file) {
        GuestSession session = validateSession(sessionId, rawToken);

        if (file == null || file.isEmpty()) {
            throw new AppException("BAD_REQUEST", "File không được để trống.");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new AppException("BAD_REQUEST", "File vượt quá giới hạn 25MB.");
        }
        String originalFilename = file.getOriginalFilename() != null ? file.getOriginalFilename() : "document.pdf";
        if (!originalFilename.toLowerCase().endsWith(".pdf")) {
            throw new AppException("BAD_REQUEST", "Chỉ hỗ trợ file định dạng PDF.");
        }

        UUID docId = UUID.randomUUID();
        String storageKey = "sessions/" + session.getId() + "/" + docId + "/original.pdf";

        try {
            minioService.upload(file, storageKey);
        } catch (Exception e) {
            throw new AppException("INTERNAL_ERROR", "Lỗi upload file lên kho lưu trữ MinIO: " + e.getMessage());
        }

        GuestDocument doc = new GuestDocument();
        doc.setId(docId);
        doc.setSessionId(session.getId());
        doc.setOriginalFilename(originalFilename);
        doc.setStorageKey(storageKey);
        doc.setContentType("application/pdf");
        doc.setFileSize(file.getSize());
        doc.setStatus(GuestDocumentStatus.PROCESSING);
        doc.setCreatedAt(Instant.now());
        doc.setExpiresAt(session.getExpiresAt());

        GuestDocument savedDoc = documentRepository.save(doc);

        session.setDocumentCount(session.getDocumentCount() + 1);
        session.setTotalSize(session.getTotalSize() + file.getSize());
        sessionRepository.save(session);

        // Kích hoạt pipeline AI ingest
        try {
            aiPipelineClient.ingest(new AiIngestRequest(
                    savedDoc.getId(),
                    savedDoc.getId(),
                    storageKey,
                    List.of("vi", "en"),
                    Map.of("title", originalFilename, "category", "GUEST_DOC", "minRole", "OPERATOR")
            ));
        } catch (Exception e) {
            log.warn("Không thể kích hoạt AI ingest cho guest doc {}: {}", savedDoc.getId(), e.getMessage());
        }

        return GuestDocumentDTO.from(savedDoc);
    }

    @Transactional(readOnly = true)
    public GuestDocumentDTO getDocumentStatus(UUID sessionId, UUID documentId, String rawToken) {
        validateSession(sessionId, rawToken);
        GuestDocument doc = documentRepository.findByIdAndSessionId(documentId, sessionId)
                .orElseThrow(() -> new NotFoundException("GuestDocument", documentId.toString()));
        return GuestDocumentDTO.from(doc);
    }

    @Transactional
    public AnswerDTO querySession(UUID sessionId, String rawToken, String question) {
        long start = System.nanoTime();
        GuestSession session = validateSession(sessionId, rawToken);

        List<GuestDocument> readyDocs = documentRepository.findBySessionIdAndStatus(sessionId, GuestDocumentStatus.READY);
        if (readyDocs.isEmpty()) {
            AnswerDTO locked = AnswerDTO.locked("Chưa có tài liệu nào trong phiên đã sẵn sàng để tra cứu.");
            saveGuestQueryLog(sessionId, question, null, BigDecimal.ZERO, false, true, locked.answer(), elapsedMs(start));
            return locked;
        }

        List<UUID> allowedDocIds = readyDocs.stream().map(GuestDocument::getId).toList();

        AiQueryResponse ai = aiPipelineClient.query(new AiQueryRequest(
                question,
                5,
                allowedDocIds,
                null,
                false,
                List.of(),
                null
        ));

        int latencyMs = elapsedMs(start);
        boolean lockedFlag = ai.guard() != null && ai.guard().locked();
        boolean numericFlag = ai.guard() != null && ai.guard().numericRule();
        boolean reasoningFlag = ai.guard() != null && ai.guard().reasoningMode();
        List<AiCitation> citations = ai.citations() != null ? ai.citations() : List.of();
        UUID matchedVersionId = citations.isEmpty() ? null : citations.getFirst().versionId();

        saveGuestQueryLog(sessionId, question, matchedVersionId,
                BigDecimal.valueOf(ai.confidence()).setScale(3, RoundingMode.HALF_UP),
                numericFlag, lockedFlag, ai.answer(), latencyMs);

        return new AnswerDTO(
                null,
                ai.answer(),
                ai.confidence(),
                new AnswerDTO.Guard(lockedFlag, numericFlag, reasoningFlag),
                citations.stream()
                        .map(c -> new AnswerDTO.Citation(c.versionId(), c.pageNo(), c.bboxKey(), c.snippet()))
                        .toList()
        );
    }

    @Transactional
    public void terminateSession(UUID sessionId, String rawToken) {
        GuestSession session = validateSession(sessionId, rawToken);
        cleanupSessionData(session);
        session.setStatus(GuestSessionStatus.TERMINATED);
        session.setDeletedAt(Instant.now());
        sessionRepository.save(session);
        log.info("Đã tiêu hủy phiên tạm: id={}", sessionId);
    }

    @Scheduled(fixedDelay = 600000) // 10 phút / lần
    @Transactional
    public void cleanupExpiredSessions() {
        Instant now = Instant.now();
        List<GuestSession> expiredSessions = sessionRepository.findByStatusAndExpiresAtBefore(GuestSessionStatus.ACTIVE, now);
        for (GuestSession session : expiredSessions) {
            try {
                log.info("Dọn dẹp phiên tạm hết hạn: id={}", session.getId());
                cleanupSessionData(session);
                session.setStatus(GuestSessionStatus.EXPIRED);
                session.setDeletedAt(now);
                sessionRepository.save(session);
            } catch (Exception e) {
                log.error("Lỗi dọn dẹp phiên tạm {}: {}", session.getId(), e.getMessage());
            }
        }
    }

    private void cleanupSessionData(GuestSession session) {
        List<GuestDocument> docs = documentRepository.findBySessionId(session.getId());
        for (GuestDocument doc : docs) {
            try {
                aiPipelineClient.deleteDocument(doc.getId());
            } catch (Exception e) {
                log.warn("Không thể xóa vector guest doc {}: {}", doc.getId(), e.getMessage());
            }
        }
        try {
            minioService.deletePrefix("sessions/" + session.getId() + "/");
        } catch (Exception e) {
            log.warn("Không thể xóa thư mục MinIO phiên {}: {}", session.getId(), e.getMessage());
        }
    }

    private GuestSession validateSession(UUID sessionId, String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new ForbiddenException("Yêu cầu header X-Session-Token.");
        }
        GuestSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("GuestSession", sessionId.toString()));

        if (session.getStatus() != GuestSessionStatus.ACTIVE) {
            throw new ForbiddenException("Phiên làm việc không còn hoạt động.");
        }

        if (session.getExpiresAt().isBefore(Instant.now())) {
            session.setStatus(GuestSessionStatus.EXPIRED);
            sessionRepository.save(session);
            throw new ForbiddenException("Phiên làm việc đã hết hạn.");
        }

        String expectedHash = session.getSessionTokenHash();
        String actualHash = hashToken(rawToken);
        if (!MessageDigest.isEqual(expectedHash.getBytes(StandardCharsets.UTF_8), actualHash.getBytes(StandardCharsets.UTF_8))) {
            throw new ForbiddenException("Session token không hợp lệ.");
        }

        session.setLastAccessedAt(Instant.now());
        return session;
    }

    private void saveGuestQueryLog(UUID sessionId, String question, UUID matchedVersionId, BigDecimal confidence,
                                   boolean numericRule, boolean locked, String answer, int latencyMs) {
        QueryLog logEntry = new QueryLog();
        logEntry.setSessionId(sessionId);
        logEntry.setQueryScope(QueryScope.GUEST_SESSION);
        logEntry.setQuestion(question);
        logEntry.setMatchedVersionId(matchedVersionId);
        logEntry.setConfidence(confidence);
        logEntry.setNumericRuleHit(numericRule);
        logEntry.setLocked(locked);
        logEntry.setAnswerPreview(answer != null && answer.length() > 500 ? answer.substring(0, 500) : answer);
        logEntry.setLatencyMs(latencyMs);
        queryLogRepository.save(logEntry);
    }

    private String generateSecureToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    private String hashToken(String raw) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(raw.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    private static int elapsedMs(long startNanos) {
        return (int) ((System.nanoTime() - startNanos) / 1_000_000);
    }
}
