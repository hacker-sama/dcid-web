package vn.dcid.service;

import org.springframework.stereotype.Service;
import vn.dcid.ai.AiPipelineClient;
import vn.dcid.ai.dto.AiCitation;
import vn.dcid.ai.dto.AiQueryRequest;
import vn.dcid.ai.dto.AiQueryResponse;
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

    public QueryService(DocumentVersionRepository versionRepository,
                        QueryLogRepository queryLogRepository,
                        AiPipelineClient aiPipelineClient) {
        this.versionRepository = versionRepository;
        this.queryLogRepository = queryLogRepository;
        this.aiPipelineClient = aiPipelineClient;
    }

    public AnswerDTO ask(QueryRequest request, UUID actorId, UserRole actorRole) {
        long start = System.nanoTime();

        List<UUID> allowed = resolveAllowedVersionIds(actorRole, request.machineCode());
        if (allowed.isEmpty()) {
            AnswerDTO locked = AnswerDTO.locked(NO_ACCESS_MESSAGE);
            saveLog(actorId, request.question(), null, null, false, true, locked.answer(), elapsedMs(start));
            return locked;
        }

        AiQueryResponse ai = aiPipelineClient.query(
                new AiQueryRequest(request.question(), TOP_K, allowed, request.machineCode()));

        int latencyMs = elapsedMs(start);
        boolean lockedFlag = ai.guard() != null && ai.guard().locked();
        boolean numericFlag = ai.guard() != null && ai.guard().numericRule();
        List<AiCitation> citations = ai.citations() != null ? ai.citations() : List.of();
        UUID matchedVersionId = citations.isEmpty() ? null : citations.getFirst().versionId();

        saveLog(actorId, request.question(), matchedVersionId,
                BigDecimal.valueOf(ai.confidence()).setScale(3, RoundingMode.HALF_UP),
                numericFlag, lockedFlag, ai.answer(), latencyMs);

        return new AnswerDTO(
                ai.answer(),
                ai.confidence(),
                new AnswerDTO.Guard(lockedFlag, numericFlag),
                citations.stream()
                        .map(c -> new AnswerDTO.Citation(c.versionId(), c.pageNo(), c.bboxKey()))
                        .toList()
        );
    }

    /** Các vai được xem = mọi minRole có ordinal ≤ vai user (thứ tự khai báo UserRole là thứ bậc). */
    private List<UUID> resolveAllowedVersionIds(UserRole actorRole, String machineCode) {
        List<UserRole> minRoles = Arrays.stream(UserRole.values())
                .filter(r -> r.ordinal() <= actorRole.ordinal())
                .toList();
        if (machineCode != null && !machineCode.isBlank()) {
            return versionRepository.findVersionIdsByStatusAndMinRolesAndMachineCode(
                    VersionStatus.ACTIVE, minRoles, machineCode);
        }
        return versionRepository.findVersionIdsByStatusAndMinRoles(VersionStatus.ACTIVE, minRoles);
    }

    private void saveLog(UUID actorId, String question, UUID matchedVersionId, BigDecimal confidence,
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
        queryLogRepository.save(logEntry);
    }

    private static int elapsedMs(long startNanos) {
        return (int) ((System.nanoTime() - startNanos) / 1_000_000);
    }
}
