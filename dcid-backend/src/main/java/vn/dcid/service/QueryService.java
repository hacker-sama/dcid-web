package vn.dcid.service;

import org.springframework.stereotype.Service;
import vn.dcid.ai.AiPipelineClient;
import vn.dcid.ai.AiStreamAuditAccumulator;
import vn.dcid.ai.dto.AiCitation;
import vn.dcid.ai.dto.AiQueryRequest;
import vn.dcid.ai.dto.AiQueryResponse;
import vn.dcid.domain.entity.DocumentVersion;
import vn.dcid.domain.entity.QueryLog;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.domain.enums.VersionStatus;
import vn.dcid.dto.request.QueryRequest;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.exception.ServiceUnavailableException;
import vn.dcid.repository.DocumentVersionRepository;
import vn.dcid.repository.QueryLogRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Hỏi–đáp RAG: BE tính allowedVersionIds theo RBAC (ACTIVE + min_role ≤ vai user),
 * gọi AI, ghi query_logs (KPI: confidence/locked/numeric_rule/latency). API-CONTRACT.md §2.
 */
@Service
public class QueryService {

    private static final int TOP_K = 5;
    private static final String NO_ACCESS_MESSAGE =
            "Không tìm thấy tài liệu phù hợp trong phạm vi quyền truy cập của bạn.";

    private final DocumentVersionRepository versionRepository;
    private final QueryLogRepository queryLogRepository;
    private final AiPipelineClient aiPipelineClient;
    private final MinioService minioService;

    public QueryService(DocumentVersionRepository versionRepository,
                        QueryLogRepository queryLogRepository,
                        AiPipelineClient aiPipelineClient,
                        MinioService minioService) {
        this.versionRepository = versionRepository;
        this.queryLogRepository = queryLogRepository;
        this.aiPipelineClient = aiPipelineClient;
        this.minioService = minioService;
    }

    public AnswerDTO ask(QueryRequest request, UUID actorId, UserRole actorRole) {
        long start = System.nanoTime();

        List<UUID> allowed = resolveAllowedVersionIds(actorRole, request.machineCode());
        if (request.selectedVersionIds() != null && !request.selectedVersionIds().isEmpty()) {
            List<UUID> selected = request.selectedVersionIds();
            allowed = versionRepository.findAllById(allowed).stream()
                    .filter(v -> selected.contains(v.getId()) || selected.contains(v.getDocumentId()))
                    .map(DocumentVersion::getId)
                    .toList();
        }

        if (allowed.isEmpty()) {
            AnswerDTO locked = AnswerDTO.locked(NO_ACCESS_MESSAGE);
            saveLog(actorId, request.question(), null, null, false, true, locked.answer(), elapsedMs(start));
            return locked;
        }

        AiQueryResponse ai = aiPipelineClient.query(
                new AiQueryRequest(
                        request.question(),
                        TOP_K,
                        allowed,
                        request.machineCode(),
                        request.reasoningMode(),
                        request.history() != null ? request.history() : List.of(),
                        null
                ));

        int latencyMs = elapsedMs(start);
        boolean lockedFlag = ai.guard() != null && ai.guard().locked();
        boolean numericFlag = ai.guard() != null && ai.guard().numericRule();
        boolean reasoningFlag = ai.guard() != null && ai.guard().reasoningMode();
        List<AiCitation> citations = ai.citations() != null ? ai.citations() : List.of();
        UUID matchedVersionId = citations.isEmpty() ? null : citations.getFirst().versionId();

        UUID logId = saveLog(actorId, request.question(), matchedVersionId,
                BigDecimal.valueOf(ai.confidence()).setScale(3, RoundingMode.HALF_UP),
                numericFlag, lockedFlag, ai.answer(), latencyMs);

        return new AnswerDTO(
                logId,
                ai.answer(),
                ai.confidence(),
                new AnswerDTO.Guard(lockedFlag, numericFlag, reasoningFlag),
                citations.stream()
                        .map(c -> new AnswerDTO.Citation(c.versionId(), c.pageNo(), c.bboxKey(), c.snippet()))
                        .toList()
        );
    }

    public AnswerDTO askWithVision(String question, String machineCode, boolean reasoningMode, org.springframework.web.multipart.MultipartFile file, UUID actorId, UserRole actorRole) {
        try {
            return askWithVision(
                    question,
                    machineCode,
                    reasoningMode,
                    file.getBytes(),
                    file.getOriginalFilename(),
                    file.getContentType(),
                    actorId,
                    actorRole);
        } catch (IOException e) {
            throw new IllegalStateException("Không thể đọc dữ liệu ảnh upload", e);
        }
    }

    public AnswerDTO askWithVision(String question, String machineCode, boolean reasoningMode,
                                   byte[] fileBytes, String originalFilename, String contentType,
                                   UUID actorId, UserRole actorRole) {
        long start = System.nanoTime();

        List<UUID> allowed = resolveAllowedVersionIds(actorRole, machineCode);
        // An uploaded image is an independent evidence source. Keep the
        // allowed-version list (possibly empty) for optional RAG enrichment,
        // but never block Snap & Ask solely because no ACTIVE document exists.

        String safeFilename = originalFilename == null || originalFilename.isBlank()
                ? "image.bin"
                : originalFilename.replaceAll(".*[\\\\/]", "");
        String imageStorageKey = "temp/vision/" + UUID.randomUUID() + "-" + safeFilename;
        minioService.upload(
                imageStorageKey,
                new ByteArrayInputStream(fileBytes),
                fileBytes.length,
                contentType != null ? contentType : "application/octet-stream");

        AiQueryResponse ai;
        try {
            ai = aiPipelineClient.query(
                    new AiQueryRequest(
                            question,
                            TOP_K,
                            allowed,
                            machineCode,
                            reasoningMode,
                            List.of(),
                            imageStorageKey
                    ));
        } finally {
            try {
                minioService.delete(imageStorageKey);
            } catch (Exception e) {
                // Ignore cleanup error
            }
        }

        if ("busy-resource-gate".equals(ai.model())) {
            throw new ServiceUnavailableException(
                    "Hệ thống AI đang bận; vui lòng thử lại sau ít phút");
        }

        int latencyMs = elapsedMs(start);
        boolean lockedFlag = ai.guard() != null && ai.guard().locked();
        boolean numericFlag = ai.guard() != null && ai.guard().numericRule();
        boolean reasoningFlag = ai.guard() != null && ai.guard().reasoningMode();
        List<AiCitation> citations = ai.citations() != null ? ai.citations() : List.of();
        UUID matchedVersionId = citations.isEmpty() ? null : citations.getFirst().versionId();

        UUID logId = saveLog(actorId, question, matchedVersionId,
                BigDecimal.valueOf(ai.confidence()).setScale(3, RoundingMode.HALF_UP),
                numericFlag, lockedFlag, ai.answer(), latencyMs);

        return new AnswerDTO(
                logId,
                ai.answer(),
                ai.confidence(),
                new AnswerDTO.Guard(lockedFlag, numericFlag, reasoningFlag),
                citations.stream()
                        .map(c -> new AnswerDTO.Citation(c.versionId(), c.pageNo(), c.bboxKey(), c.snippet()))
                        .toList()
        );
    }

    /** Các vai được xem = mọi minRole có level ≤ level của vai user (dùng getLevel() thay ordinal()). */
    private List<UUID> resolveAllowedVersionIds(UserRole actorRole, String machineCode) {
        List<UserRole> minRoles = Arrays.stream(UserRole.values())
                .filter(r -> r.getLevel() <= actorRole.getLevel())
                .toList();
        if (machineCode != null && !machineCode.isBlank()) {
            return versionRepository.findVersionIdsByStatusAndMinRolesAndMachineCode(
                    VersionStatus.ACTIVE, minRoles, machineCode);
        }
        return versionRepository.findVersionIdsByStatusAndMinRoles(VersionStatus.ACTIVE, minRoles);
    }

    private UUID saveLog(UUID actorId, String question, UUID matchedVersionId, BigDecimal confidence,
                         boolean numericRule, boolean locked, String answer, int latencyMs) {
        QueryLog logEntry = new QueryLog();
        logEntry.setActorId(actorId);
        logEntry.setQuestion(question);
        logEntry.setMatchedVersionId(matchedVersionId);
        logEntry.setConfidence(confidence);
        logEntry.setNumericRuleHit(numericRule);
        logEntry.setLocked(locked);
        logEntry.setAnswerPreview(answer != null && answer.length() > 500 ? answer.substring(0, 500) : answer);
        logEntry.setLatencyMs(latencyMs);
        return queryLogRepository.save(logEntry).getId();
    }

    private static int elapsedMs(long startNanos) {
        return (int) ((System.nanoTime() - startNanos) / 1_000_000);
    }

    public SseEmitter askStreaming(QueryRequest request, UUID actorId, UserRole actorRole) {
        long requestStart = System.nanoTime();
        List<UUID> allowed = resolveAllowedVersionIds(actorRole, request.machineCode());
        if (request.selectedVersionIds() != null && !request.selectedVersionIds().isEmpty()) {
            List<UUID> selected = request.selectedVersionIds();
            allowed = versionRepository.findAllById(allowed).stream()
                    .filter(v -> selected.contains(v.getId()) || selected.contains(v.getDocumentId()))
                    .map(DocumentVersion::getId)
                    .toList();
        }

        SseEmitter emitter = new SseEmitter(TimeUnit.MINUTES.toMillis(10));

        if (allowed.isEmpty()) {
            try {
                saveLog(actorId, request.question(), null, null, false, true,
                        NO_ACCESS_MESSAGE, elapsedMs(requestStart));
                emitter.send("{\"event\":\"meta\",\"citations\":[],\"confidence\":0.0,"
                        + "\"guard\":{\"locked\":true,\"numericRule\":false,\"reasoningMode\":false}}");
                emitter.send("{\"event\":\"delta\",\"text\":\"" + NO_ACCESS_MESSAGE + "\"}");
                emitter.send("{\"event\":\"done\",\"latencyMs\":" + elapsedMs(requestStart)
                        + ",\"model\":\"guardrail-no-access\"}");
                emitter.complete();
            } catch (Exception e) {
                emitter.completeWithError(e);
            }
            return emitter;
        }

        final List<UUID> finalAllowed = allowed;
        CompletableFuture.runAsync(() -> {
            long start = System.nanoTime();
            AiStreamAuditAccumulator audit = new AiStreamAuditAccumulator();
            AtomicBoolean auditSaved = new AtomicBoolean(false);
            Runnable saveStreamAudit = () -> {
                if (!auditSaved.compareAndSet(false, true)) {
                    return;
                }
                Double confidence = audit.confidence();
                saveLog(
                        actorId,
                        request.question(),
                        audit.matchedVersionId(),
                        confidence != null
                                ? BigDecimal.valueOf(confidence).setScale(3, RoundingMode.HALF_UP)
                                : null,
                        audit.numericRule(),
                        audit.locked(),
                        audit.answerPreview(),
                        elapsedMs(start)
                );
            };
            aiPipelineClient.queryStream(
                new AiQueryRequest(
                    request.question(),
                    TOP_K,
                    finalAllowed,
                    request.machineCode(),
                    request.reasoningMode(),
                    request.history() != null ? request.history() : List.of(),
                    null
                ),
                token -> {
                    try {
                        audit.accept(token);
                        emitter.send(token);
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                },
                () -> {
                    saveStreamAudit.run();
                    emitter.complete();
                },
                e -> {
                    audit.markTransportError(e);
                    saveStreamAudit.run();
                    emitter.completeWithError(e);
                }
            );
        });

        return emitter;
    }
}
