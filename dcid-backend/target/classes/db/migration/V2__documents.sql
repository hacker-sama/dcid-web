-- V2__documents.sql
-- Tài liệu kỹ thuật + version + trang.
-- Vector/chunk KHÔNG ở đây (sống trong ChromaDB); Postgres chỉ giữ metadata quan hệ.

-- ---------------------------------------------------------------------------
-- documents: 1 tài liệu logic của 1 máy/loại thiết bị
-- ---------------------------------------------------------------------------
CREATE TABLE documents (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title        VARCHAR(255) NOT NULL,
    machine_code VARCHAR(100),                         -- mã máy/chuyền (khớp CMMS)
    category     VARCHAR(50) NOT NULL
                 CHECK (category IN ('SOP', 'DRAWING', 'CIRCUIT', 'MAINTENANCE_LOG', 'SAFETY', 'OTHER')),
    min_role     VARCHAR(50) NOT NULL DEFAULT 'OPERATOR' -- vai tối thiểu được xem
                 CHECK (min_role IN ('OPERATOR', 'ENGINEER', 'QA_ADMIN', 'ADMIN')),
    description  TEXT,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by   UUID
);

CREATE INDEX idx_documents_machine_code ON documents(machine_code);
CREATE INDEX idx_documents_category ON documents(category);

CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ---------------------------------------------------------------------------
-- document_versions: mỗi lần upload = 1 version (vòng đời qua cột status)
-- ---------------------------------------------------------------------------
CREATE TABLE document_versions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id       UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    version_no        INT NOT NULL,
    storage_key       VARCHAR(512) NOT NULL,            -- key PDF gốc trong MinIO
    original_filename VARCHAR(255),
    content_type      VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    file_size         BIGINT,
    checksum          VARCHAR(64),                      -- sha256, phát hiện trùng
    lang              VARCHAR(20),                      -- 'vi', 'en', 'vi,en'
    page_count        INT,
    status            VARCHAR(20) NOT NULL DEFAULT 'PROCESSING'
                      CHECK (status IN ('PROCESSING', 'READY', 'ACTIVE', 'SUPERSEDED', 'OBSOLETE', 'FAILED')),
    error_message     TEXT,                             -- khi status = FAILED
    ingested_at       TIMESTAMP WITH TIME ZONE,         -- khi AI hoàn tất index
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by        UUID,
    CONSTRAINT uq_document_versions_no UNIQUE (document_id, version_no)
);

CREATE INDEX idx_document_versions_document_id ON document_versions(document_id);
CREATE INDEX idx_document_versions_status ON document_versions(status);

-- Bất biến nghiệp vụ: mỗi tài liệu chỉ có tối đa 1 version ACTIVE
CREATE UNIQUE INDEX uq_document_versions_active
    ON document_versions(document_id) WHERE status = 'ACTIVE';

CREATE TRIGGER update_document_versions_updated_at
    BEFORE UPDATE ON document_versions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ---------------------------------------------------------------------------
-- document_pages: map trang ↔ ảnh (để vẽ bounding-box theo toạ độ chuẩn hoá)
-- ---------------------------------------------------------------------------
CREATE TABLE document_pages (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID NOT NULL REFERENCES document_versions(id) ON DELETE CASCADE,
    page_no    INT NOT NULL,
    image_key  VARCHAR(512),                            -- key ảnh trang trong MinIO
    width      INT,                                     -- px, để chuẩn hoá bbox
    height     INT,
    ocr_text   TEXT,                                    -- text OCR của trang (tuỳ chọn)
    CONSTRAINT uq_document_pages_no UNIQUE (version_id, page_no)
);

CREATE INDEX idx_document_pages_version_id ON document_pages(version_id);
