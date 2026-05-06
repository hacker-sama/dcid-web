-- V2__create_procedures.sql
CREATE TABLE procedure_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    json_schema TEXT,
    estimated_days INTEGER,
    fee NUMERIC(12, 2),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_procedure_types_code ON procedure_types(code);
CREATE INDEX idx_procedure_types_is_active ON procedure_types(is_active);

CREATE TRIGGER update_procedure_types_updated_at
    BEFORE UPDATE ON procedure_types
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
