-- V5__guest_sessions.sql
-- Bảng quản lý phiên hỏi đáp tạm ẩn danh và tài liệu tải lên tạm thời (Phân hệ B)

CREATE TABLE guest_sessions (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_token_hash VARCHAR(64) NOT NULL UNIQUE,
    status             VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'TERMINATED')),
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    last_accessed_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_hash            VARCHAR(64),
    document_count     INT NOT NULL DEFAULT 0,
    total_size         BIGINT NOT NULL DEFAULT 0,
    deleted_at         TIMESTAMP WITH TIME ZONE
);

CREATE TABLE guest_documents (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id        UUID NOT NULL REFERENCES guest_sessions(id) ON DELETE CASCADE,
    original_filename VARCHAR(255),
    storage_key       VARCHAR(512) NOT NULL,
    content_type      VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    file_size         BIGINT NOT NULL,
    checksum          VARCHAR(64),
    status            VARCHAR(20) NOT NULL DEFAULT 'PROCESSING' CHECK (status IN ('PROCESSING', 'READY', 'FAILED')),
    page_count        INT,
    error_message     TEXT,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at        TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_guest_sessions_expires_at ON guest_sessions(expires_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_guest_documents_session_id ON guest_documents(session_id);

-- Cập nhật query_logs để ghi log truy vấn ẩn danh
ALTER TABLE query_logs ALTER COLUMN actor_id DROP NOT NULL;
ALTER TABLE query_logs ADD COLUMN session_id UUID REFERENCES guest_sessions(id) ON DELETE SET NULL;
ALTER TABLE query_logs ADD COLUMN query_scope VARCHAR(20) NOT NULL DEFAULT 'OFFICIAL' CHECK (query_scope IN ('OFFICIAL', 'GUEST_SESSION'));
