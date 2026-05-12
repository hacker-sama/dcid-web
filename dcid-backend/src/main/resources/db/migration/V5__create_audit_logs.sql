-- V5__create_audit_logs.sql

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL,
    actor_role VARCHAR(50) NOT NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    ip_address VARCHAR(45),
    detail JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

COMMENT ON TABLE audit_logs IS
'Immutable audit trail. No UPDATE or DELETE allowed on this table.
 Enforce via application layer and database role permissions.';
