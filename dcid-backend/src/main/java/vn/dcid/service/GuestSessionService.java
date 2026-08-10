package vn.dcid.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import vn.dcid.ai.AiPipelineClient;
import vn.dcid.ai.dto.AiIngestRequest;
import vn.dcid.ai.dto.AiQueryRequest;
import vn.dcid.ai.dto.AiQueryResponse;
import vn.dcid.ai.dto.AiCitation;
import vn.dcid.domain.entity.GuestDocument;
import vn.dcid.domain.entity.GuestSession;
import vn.dcid.domain.entity.QueryLog;
import vn.dcid.domain.enums.QueryScope;
import vn.dcid.domain.enums.SessionStatus;
import vn.dcid.domain.enums.VersionStatus;
import vn.dcid.dto.request.QueryRequest;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.dto.response.CreateSessionResponse;
import vn.dcid.dto.response.GuestDocumentDTO;
import vn.dcid.dto.response.GuestSessionDTO;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.exception.NotFoundException;
import vn.dcid.exception.PolicyViolationException;
import vn.dcid.repository.GuestDocumentRepository;
import vn.dcid.repository.GuestSessionRepository;
import vn.dcid.repository.QueryLogRepository;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class GuestSessionService {

    private static final Logger log = LoggerFactory.getLogger(GuestSessionService.class);
    private static final int DEFAULT_TTL_HOURS = 2;
    private static final int MAX_DOCUMENTS_PER_SESSION = 3;
    private static final long MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024; // 25MB

    private final GuestSessionRepository sessionRepository;
    private final GuestDocumentRepository documentRepository;
    private final QueryLogRepository queryLogRepository;
    private final MinioService minioService;
    private final AiPipelineClient aiPipelineClient;

    public GuestSessionService(GuestSessionRepository sessionRepository,
                               GuestDocumentRepository documentRepository,
                               QueryLogRepository queryLogRepository,
                               MinioService minioService,
                               AiPipelineClient aiPipelineClient) {
        this.sessionRepository = sessionRepository;
        this.documentRepository = documentRepository;
        this.queryLogRepository = queryLogRepository;
        this.minioService = minioService;
        this.aiPipelineClient = aiPipelineClient;
    }

    /** Tạo một phiên hỏi đáp công khai mới (GuestSession). */
    @Transactional
    public CreateSessionResponse createSession(String clientIp) {
        String tokenBytes = generateRandomToken();
        String tokenHash = sha256(tokenBytes);

        GuestSession session = new GuestSession();
        session.setSessionTokenHash(tokenHash);
        session.setStatus(SessionStatus.ACTIVE);
        session.setCreatedAt(Instant.now());
        session.setExpiresAt(Instant.now().plus(DEFAULT_TTL_HOURS, ChronoUnit.HOURS));
        session.setLastAccessedAt(Instant.now());
        session.setIpHash(clientIp != null ? sha256(clientIp) : null);
        session = sessionRepository.save(session);

        log.info("Tạo guest session mới id={}, expiresAt={}", session.getId(), session.getExpiresAt());
        return new CreateSessionResponse(session.getId(), tokenBytes, session.getExpiresAt());
    }

    /** Upload tài liệu tạm PDF vào phiên công khai. */
    @Transactional
    public GuestDocumentDTO uploadDocument(UUID sessionId, String token, MultipartFile file) {
        GuestSession session = validateAndTouchSession(sessionId, token);

        if (file == null || file.isEmpty()) {
            throw new PolicyViolationException("File rỗng hoặc không hợp lệ.");
        }
        if (file.getSize() > MAX_FILE_SIZE_BYTES) {
            throw new PolicyViolationException("Dung lượng file tối đa là 25MB.");
        }
        if (session.getDocumentCount() >= MAX_DOCUMENTS_PER_SESSION) {
            throw new PolicyViolationException("Mỗi phiên chỉ được tải tối đa " + MAX_DOCUMENTS_PER_SESSION + " tài liệu.");
        }

        final byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            throw new PolicyViolationException("Không đọc được nội dung file: " + e.getMessage());
        }

        UUID docId = UUID.randomUUID();
        String storageKey = "sessions/" + sessionId + "/" + docId + "/original.pdf";
        String contentType = file.getContentType() != null ? file.getContentType() : "application/pdf";
        minioService.upload(storageKey, new ByteArrayInputStream(bytes), bytes.length, contentType);

        GuestDocument doc = new GuestDocument();
        doc.setId(docId);
        doc.setSessionId(sessionId);
        doc.setOriginalFilename(file.getOriginalFilename());
        doc.setStorageKey(storageKey);
        doc.setContentType(contentType);
        doc.setFileSize((long) bytes.length);
        doc.setChecksum(sha256(bytes));
        doc.setStatus(VersionStatus.PROCESSING);
        doc.setCreatedAt(Instant.now());
        doc.setExpiresAt(session.getExpiresAt());
        doc = documentRepository.save(doc);

        session.setDocumentCount(session.getDocumentCount() + 1);
        session.setTotalSize(session.getTotalSize() + bytes.length);
        sessionRepository.save(session);

        // Kích hoạt AI ingest bất đồng bộ
        triggerGuestIngest(session, doc);

        return GuestDocumentDTO.from(doc);
    }

    /** Hỏi đáp RAG trong phạm vi tài liệu thuộc phiên tạm. */
    @Transactional
    public AnswerDTO askQuestion(UUID sessionId, String token, QueryRequest request) {
        long start = System.nanoTime();
        GuestSession session = validateAndTouchSession(sessionId, token);

        List<GuestDocument> docs = documentRepository.findBySessionId(sessionId);
        List<UUID> readyDocIds = docs.stream()
                .filter(d -> d.getStatus() == VersionStatus.READY || d.getStatus() == VersionStatus.ACTIVE)
                .map(GuestDocument::getId)
                .toList();

        if (readyDocIds.isEmpty()) {
            AnswerDTO locked = AnswerDTO.locked("Chưa có tài liệu nào sẵn sàng trong phiên làm việc này.");
            saveGuestLog(sessionId, request.question(), null, null, false, true, locked.answer(), elapsedMs(start));
            return locked;
        }

        AiQueryResponse ai = aiPipelineClient.query(
                new AiQueryRequest(
                        request.question(),
                        5,
                        readyDocIds,
                        request.machineCode(),
                        request.reasoningMode(),
                        request.history() != null ? request.history() : List.of(),
                        null
                )
        );

        int latencyMs = elapsedMs(start);
        boolean lockedFlag = ai.guard() != null && ai.guard().locked();
        boolean numericFlag = ai.guard() != null && ai.guard().numericRule();
        boolean reasoningFlag = ai.guard() != null && ai.guard().reasoningMode();
        List<AiCitation> citations = ai.citations() != null ? ai.citations() : List.of();
        UUID matchedVersionId = citations.isEmpty() ? null : citations.getFirst().versionId();

        saveGuestLog(sessionId, request.question(), matchedVersionId,
                BigDecimal.valueOf(ai.confidence()).setScale(3, RoundingMode.HALF_UP),
                numericFlag, lockedFlag, ai.answer(), latencyMs);

        return new AnswerDTO(
                ai.answer(),
                ai.confidence(),
                new AnswerDTO.Guard(lockedFlag, numericFlag, reasoningFlag),
                citations.stream()
                        .map(c -> new AnswerDTO.Citation(c.versionId(), c.pageNo(), c.bboxKey(), c.snippet()))
                        .toList()
        );
    }

    /** Người dùng chủ động kết thúc phiên và xóa toàn bộ dữ liệu tạm. */
    @Transactional
    public void deleteSession(UUID sessionId, String token) {
        GuestSession session = validateAndTouchSession(sessionId, token);

        List<GuestDocument> docs = documentRepository.findBySessionId(sessionId);
        for (GuestDocument doc : docs) {
            try {
                minioService.delete(doc.getStorageKey());
            } catch (Exception e) {
                log.warn("Không thể xóa file MinIO guest doc storageKey={}: {}", doc.getStorageKey(), e.getMessage());
            }
        }

        try {
            aiPipelineClient.deleteGuestSessionVectors(sessionId);
        } catch (Exception e) {
            log.warn("Không thể xóa vector Qdrant cho sessionId={}: {}", sessionId, e.getMessage());
        }

        session.setStatus(SessionStatus.TERMINATED);
        session.setDeletedAt(Instant.now());
        sessionRepository.save(session);

        log.info("Người dùng đã kết thúc phiên ẩn danh sessionId={}", sessionId);
    }

    /** Lấy chi tiết phiên công khai. */
    @Transactional(readOnly = true)
    public GuestSessionDTO getSessionDetail(UUID sessionId, String token) {
        GuestSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("GuestSession", sessionId.toString()));
        if (!sha256(token).equals(session.getSessionTokenHash()) || session.getDeletedAt() != null) {
            throw new ForbiddenException("Phiên không hợp lệ.");
        }
        List<GuestDocumentDTO> docs = documentRepository.findBySessionId(sessionId)
                .stream().map(GuestDocumentDTO::from).toList();
        return GuestSessionDTO.from(session, docs);
    }

    /** Lấy trạng thái tài liệu thuộc phiên. */
    @Transactional(readOnly = true)
    public GuestDocumentDTO getDocumentStatus(UUID sessionId, UUID documentId, String token) {
        getSessionDetail(sessionId, token);
        GuestDocument doc = documentRepository.findByIdAndSessionId(documentId, sessionId)
                .orElseThrow(() -> new NotFoundException("GuestDocument", documentId.toString()));
        return GuestDocumentDTO.from(doc);
    }

    private GuestSession validateAndTouchSession(UUID sessionId, String token) {
        GuestSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("GuestSession", sessionId.toString()));

        if (session.getDeletedAt() != null || session.getStatus() != SessionStatus.ACTIVE) {
            throw new ForbiddenException("Phiên làm việc đã bị vô hiệu hóa.");
        }
        if (!sha256(token).equals(session.getSessionTokenHash())) {
            throw new ForbiddenException("Token xác thực phiên không hợp lệ.");
        }
        if (session.getExpiresAt().isBefore(Instant.now())) {
            session.setStatus(SessionStatus.EXPIRED);
            sessionRepository.save(session);
            throw new ForbiddenException("Phiên làm việc đã hết hạn (TTL).");
        }

        // Gia hạn TTL khi người dùng có hoạt động
        session.setLastAccessedAt(Instant.now());
        session.setExpiresAt(Instant.now().plus(DEFAULT_TTL_HOURS, ChronoUnit.HOURS));
        return sessionRepository.save(session);
    }

    private void triggerGuestIngest(GuestSession session, GuestDocument doc) {
        Map<String, String> metadata = new LinkedHashMap<>();
        metadata.put("title", doc.getOriginalFilename());
        metadata.put("sessionId", session.getId().toString());

        try {
            aiPipelineClient.ingest(new AiIngestRequest(
                    doc.getId(), session.getId(), doc.getStorageKey(), List.of("vi", "en"), metadata));
        } catch (Exception e) {
            log.error("Lỗi gọi AI ingest cho guest document {}", doc.getId(), e);
            doc.setStatus(VersionStatus.FAILED);
            doc.setErrorMessage("Không thể xử lý AI ingest: " + e.getMessage());
            documentRepository.save(doc);
        }
    }

    private void saveGuestLog(UUID sessionId, String question, UUID matchedVersionId, BigDecimal confidence,
                              boolean numericRule, boolean locked, String answer, int latencyMs) {
        QueryLog logEntry = new QueryLog();
        logEntry.setActorId(null);
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

    private static String generateRandomToken() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    private static String sha256(String data) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(data.getBytes());
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            return data;
        }
    }

    private static String sha256(byte[] bytes) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(bytes);
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            return null;
        }
    }

    private static int elapsedMs(long startNanos) {
        return (int) ((System.nanoTime() - startNanos) / 1_000_000);
    }
}
