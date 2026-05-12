-- V6__create_indexes.sql

CREATE INDEX idx_applications_applicant_id
  ON applications(applicant_id);

COMMENT ON INDEX idx_applications_applicant_id IS
  'Citizen queries own applications list';

CREATE INDEX idx_applications_status
  ON applications(status);

COMMENT ON INDEX idx_applications_status IS
  'Officer filters application queue by status';

CREATE INDEX idx_applications_officer_status
  ON applications(assigned_officer_id, status);

COMMENT ON INDEX idx_applications_officer_status IS
  'Officer views own assigned applications filtered by status';

CREATE INDEX idx_applications_procedure_submitted
  ON applications(procedure_type_id, submitted_at DESC)
  WHERE submitted_at IS NOT NULL;

COMMENT ON INDEX idx_applications_procedure_submitted IS
  'Monthly report queries by procedure type and submission date';

CREATE INDEX idx_status_history_application
  ON application_status_history(application_id, changed_at DESC);

COMMENT ON INDEX idx_status_history_application IS
  'Load status timeline for a specific application';

CREATE INDEX idx_notifications_user_unread
  ON notifications(user_id, is_read, created_at DESC)
  WHERE is_read = false;

COMMENT ON INDEX idx_notifications_user_unread IS
  'Partial index for unread notification count per user';

CREATE INDEX idx_audit_logs_actor
  ON audit_logs(actor_id, created_at DESC);

COMMENT ON INDEX idx_audit_logs_actor IS
  'Admin searches audit log by specific officer';

CREATE INDEX idx_audit_logs_resource
  ON audit_logs(resource_type, resource_id, created_at DESC);

COMMENT ON INDEX idx_audit_logs_resource IS
  'Admin views all actions performed on a specific resource';
