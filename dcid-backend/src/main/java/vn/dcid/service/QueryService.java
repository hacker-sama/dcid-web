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
import vn.dcid.repository.DocumentVersionRepository;
import vn.dcid.repository.QueryLogRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
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
        long start = System.nanoTime();

        List<UUID> allowed = resolveAllowedVersionIds(actorRole, machineCode);

        if (allowed.isEmpty()) {
            AnswerDTO locked = AnswerDTO.locked(NO_ACCESS_MESSAGE);
            saveLog(actorId, question, null, null, false, true, locked.answer(), elapsedMs(start));
            return locked;
        }

        String imageStorageKey = "temp/vision/" + UUID.randomUUID() + "-" + file.getOriginalFilename();
        minioService.upload(file, imageStorageKey);

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
                UUID logId = saveLog(actorId, request.question(), null, null, false, true,
                        NO_ACCESS_MESSAGE, elapsedMs(requestStart));
                emitter.send("{\"event\":\"meta\",\"citations\":[],\"confidence\":0.0,"
                        + "\"guard\":{\"locked\":true,\"numericRule\":false,\"reasoningMode\":false}}");
                emitter.send("{\"event\":\"delta\",\"text\":\"" + NO_ACCESS_MESSAGE + "\"}");
                emitter.send("{\"event\":\"done\",\"logId\":\"" + (logId != null ? logId.toString() : "") + "\",\"latencyMs\":" + elapsedMs(requestStart)
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
            java.util.concurrent.atomic.AtomicReference<UUID> savedLogId = new java.util.concurrent.atomic.AtomicReference<>(null);

            java.util.function.Supplier<UUID> saveStreamAudit = () -> {
                if (!auditSaved.compareAndSet(false, true)) {
                    return savedLogId.get();
                }
                Double confidence = audit.confidence();
                UUID id = saveLog(
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
                savedLogId.set(id);
                return id;
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
                        if (token.contains("\"event\":\"done\"") || token.contains("\"event\": \"done\"")) {
                            UUID logId = saveStreamAudit.get();
                            if (logId != null) {
                                String enrichedDone = token.replaceFirst("\\{", "{\"logId\":\"" + logId + "\",");
                                emitter.send(enrichedDone);
                                return;
                            }
                        }
                        emitter.send(token);
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                },
                () -> {
                    UUID logId = saveStreamAudit.get();
                    if (!audit.locked() && logId != null) {
                        try {
                            emitter.send("{\"event\":\"done\",\"logId\":\"" + logId + "\",\"latencyMs\":" + elapsedMs(start) + "}");
                        } catch (Exception ignored) {}
                    }
                    emitter.complete();
                },
                e -> {
                    audit.markTransportError(e);
                    saveStreamAudit.get();
                    emitter.completeWithError(e);
                }
            );
        });

        return emitter;
    }
}
