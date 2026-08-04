-- V3__query_logs.sql
-- Nhật ký hỏi–đáp: phục vụ audit ISO + đo latency + hậu kiểm hallucination số liệu.

CREATE TABLE query_logs (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id           UUID NOT NULL REFERENCES users(id),
    question           TEXT NOT NULL,
    matched_version_id UUID REFERENCES document_versions(id) ON DELETE SET NULL,
    confidence         NUMERIC(4, 3),                   -- 0.000 .. 1.000 (cosine top-1)
    numeric_rule_hit   BOOLEAN NOT NULL DEFAULT false,  -- trích số liệu bằng rule (không do LLM)
    locked             BOOLEAN NOT NULL DEFAULT false,  -- guardrail khoá câu trả lời tự sinh
    answer_preview     TEXT,                            -- trích đoạn câu trả lời (tuỳ chọn)
    latency_ms         INT,
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_query_logs_actor_id ON query_logs(actor_id);
CREATE INDEX idx_query_logs_created_at ON query_logs(created_at);
