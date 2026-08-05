-- V4__work_orders.sql
-- Tích hợp CMMS/MES: nhận Work Order + deep-link tới đúng trang tài liệu.
-- (Bảng sẵn sàng; luồng tích hợp triển khai ở giai đoạn sau — ngoài scope 6 tuần.)

CREATE TABLE work_orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cmms_ref            VARCHAR(100) UNIQUE,             -- id Work Order bên CMMS
    machine_code        VARCHAR(100),
    title               VARCHAR(255),
    document_version_id UUID REFERENCES document_versions(id) ON DELETE SET NULL,
    deep_link           VARCHAR(512),                    -- link tới đúng trang tài liệu
    status              VARCHAR(20) NOT NULL DEFAULT 'OPEN'
                        CHECK (status IN ('OPEN', 'IN_PROGRESS', 'DONE', 'CANCELLED')),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_work_orders_machine_code ON work_orders(machine_code);
CREATE INDEX idx_work_orders_status ON work_orders(status);

CREATE TRIGGER update_work_orders_updated_at
    BEFORE UPDATE ON work_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
