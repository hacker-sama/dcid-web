-- V6__create_indexes.sql
-- Composite indexes for common query patterns

-- Applications: Find pending applications for an officer
CREATE INDEX idx_applications_officer_status ON applications(assigned_officer_id, status)
    WHERE assigned_officer_id IS NOT NULL;

-- Applications: Find overdue applications
CREATE INDEX idx_applications_overdue ON applications(status, estimated_completion_at)
    WHERE status IN ('IN_REVIEW', 'PENDING_SUPPLEMENT') AND estimated_completion_at < CURRENT_TIMESTAMP;

-- Applications: Find urgent applications
CREATE INDEX idx_applications_urgent ON applications(is_urgent, status)
    WHERE is_urgent = true;

-- Applications: Find applications by procedure type and status
CREATE INDEX idx_applications_procedure_status ON applications(procedure_type_id, status);

-- Notifications: Find unread notifications for a user
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC)
    WHERE is_read = false;

-- Appointments: Find upcoming appointments for an officer
CREATE INDEX idx_appointments_officer_upcoming ON appointments(officer_id, scheduled_at, status)
    WHERE scheduled_at > CURRENT_TIMESTAMP AND status = 'SCHEDULED';

-- Appointments: Find upcoming appointments for a citizen
CREATE INDEX idx_appointments_citizen_upcoming ON appointments(citizen_id, scheduled_at, status)
    WHERE scheduled_at > CURRENT_TIMESTAMP AND status = 'SCHEDULED';

-- Audit logs: Find recent activity for a specific resource
CREATE INDEX idx_audit_logs_resource_recent ON audit_logs(resource_type, resource_id, created_at DESC)
    WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '30 days';

-- Status history: Find recent status changes for an application
CREATE INDEX idx_status_history_app_recent ON application_status_history(application_id, changed_at DESC)
    WHERE changed_at > CURRENT_TIMESTAMP - INTERVAL '30 days';
