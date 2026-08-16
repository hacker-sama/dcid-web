package vn.dcid.domain.entity;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Nhật ký hỏi–đáp: audit ISO + đo latency + hậu kiểm hallucination số liệu. */
@Entity
@Table(name = "query_logs")
public class QueryLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "actor_id")
    private UUID actorId;

    @Column(name = "question", nullable = false, columnDefinition = "TEXT")
    private String question;

    @Column(name = "matched_version_id")
    private UUID matchedVersionId;

    /** Cosine top-1 (0.000..1.000). */
    @Column(name = "confidence", precision = 4, scale = 3)
    private BigDecimal confidence;

    /** Câu trả lời trích số liệu bằng rule (không do LLM sinh). */
    @Column(name = "numeric_rule_hit", nullable = false)
    private Boolean numericRuleHit = false;

    /** Guardrail đã khoá câu trả lời tự sinh. */
    @Column(name = "locked", nullable = false)
    private Boolean locked = false;

    @Column(name = "answer_preview", columnDefinition = "TEXT")
    private String answerPreview;

    @Column(name = "latency_ms")
    private Integer latencyMs;

    @Column(name = "session_id")
    private UUID sessionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "query_scope", nullable = false, length = 20)
    private vn.dcid.domain.enums.QueryScope queryScope = vn.dcid.domain.enums.QueryScope.OFFICIAL;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = Instant.now();
        if (queryScope == null) {
            queryScope = vn.dcid.domain.enums.QueryScope.OFFICIAL;
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getActorId() {
        return actorId;
    }

    public void setActorId(UUID actorId) {
        this.actorId = actorId;
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

    public UUID getMatchedVersionId() {
        return matchedVersionId;
    }

    public void setMatchedVersionId(UUID matchedVersionId) {
        this.matchedVersionId = matchedVersionId;
    }

    public BigDecimal getConfidence() {
        return confidence;
    }

    public void setConfidence(BigDecimal confidence) {
        this.confidence = confidence;
    }

    public Boolean getNumericRuleHit() {
        return numericRuleHit;
    }

    public void setNumericRuleHit(Boolean numericRuleHit) {
        this.numericRuleHit = numericRuleHit;
    }

    public Boolean getLocked() {
        return locked;
    }

    public void setLocked(Boolean locked) {
        this.locked = locked;
    }

    public String getAnswerPreview() {
        return answerPreview;
    }

    public void setAnswerPreview(String answerPreview) {
        this.answerPreview = answerPreview;
    }

    public Integer getLatencyMs() {
        return latencyMs;
    }

    public void setLatencyMs(Integer latencyMs) {
        this.latencyMs = latencyMs;
    }

    public UUID getSessionId() {
        return sessionId;
    }

    public void setSessionId(UUID sessionId) {
        this.sessionId = sessionId;
    }

    public vn.dcid.domain.enums.QueryScope getQueryScope() {
        return queryScope;
    }

    public void setQueryScope(vn.dcid.domain.enums.QueryScope queryScope) {
        this.queryScope = queryScope;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
