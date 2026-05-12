-- V3__create_applications.sql

CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference_number VARCHAR(50) NOT NULL UNIQUE,
    procedure_type_id UUID NOT NULL REFERENCES procedure_types(id),
    applicant_id UUID NOT NULL REFERENCES users(id),
    assigned_officer_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    form_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    signature_data TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

    CONSTRAINT chk_status CHECK (status IN (
      'DRAFT','SUBMITTED','IN_REVIEW','PENDING_SUPPLEMENT',
      'APPROVED','REJECTED','WITHDRAWN'
    ))
);

CREATE SEQUENCE application_ref_seq START 1;

CREATE OR REPLACE FUNCTION generate_reference_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.reference_number := 'CDS-' || to_char(now(), 'YYYY') || '-' ||
                          LPAD(nextval('application_ref_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_ref
BEFORE INSERT ON applications
FOR EACH ROW
WHEN (NEW.reference_number IS NULL OR NEW.reference_number = '')
EXECUTE FUNCTION generate_reference_number();

CREATE TRIGGER trg_applications_updated_at
BEFORE UPDATE ON applications
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE application_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    minio_key VARCHAR(500) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE application_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    from_status VARCHAR(50),
    to_status VARCHAR(50) NOT NULL,
    changed_by_id UUID REFERENCES users(id),
    note TEXT,
    changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
