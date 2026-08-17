-- V6: Thêm cột feedback cho query_logs
ALTER TABLE query_logs
    ADD COLUMN IF NOT EXISTS feedback SMALLINT,
    ADD COLUMN IF NOT EXISTS feedback_note TEXT,
    ADD COLUMN IF NOT EXISTS feedback_at TIMESTAMPTZ;

COMMENT ON COLUMN query_logs.feedback IS '1 = helpful, -1 = not helpful, NULL = no feedback';
