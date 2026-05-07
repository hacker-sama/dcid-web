package vn.dcid.domain.entity;

import jakarta.persistence.*;
import vn.dcid.common.AuditableEntity;
import vn.dcid.domain.enums.ApplicationStatus;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "applications")
public class Application extends AuditableEntity {

    @Column(name = "applicant_id", nullable = false)
    private UUID applicantId;

    @Column(name = "procedure_type_id", nullable = false)
    private UUID procedureTypeId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    private ApplicationStatus status = ApplicationStatus.DRAFT;

    @Column(name = "assigned_officer_id")
    private UUID assignedOfficerId;

    @Column(name = "submitted_at")
    private Instant submittedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "estimated_completion_at")
    private Instant estimatedCompletionAt;

    @Column(name = "form_data", columnDefinition = "JSONB")
    private String formData;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "is_urgent", nullable = false)
    private Boolean isUrgent = false;

    public UUID getApplicantId() {
        return applicantId;
    }

    public void setApplicantId(UUID applicantId) {
        this.applicantId = applicantId;
    }

    public UUID getProcedureTypeId() {
        return procedureTypeId;
    }

    public void setProcedureTypeId(UUID procedureTypeId) {
        this.procedureTypeId = procedureTypeId;
    }

    public ApplicationStatus getStatus() {
        return status;
    }

    public void setStatus(ApplicationStatus status) {
        this.status = status;
    }

    public UUID getAssignedOfficerId() {
        return assignedOfficerId;
    }

    public void setAssignedOfficerId(UUID assignedOfficerId) {
        this.assignedOfficerId = assignedOfficerId;
    }

    public Instant getSubmittedAt() {
        return submittedAt;
    }

    public void setSubmittedAt(Instant submittedAt) {
        this.submittedAt = submittedAt;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(Instant completedAt) {
        this.completedAt = completedAt;
    }

    public Instant getEstimatedCompletionAt() {
        return estimatedCompletionAt;
    }

    public void setEstimatedCompletionAt(Instant estimatedCompletionAt) {
        this.estimatedCompletionAt = estimatedCompletionAt;
    }

    public String getFormData() {
        return formData;
    }

    public void setFormData(String formData) {
        this.formData = formData;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public Boolean getIsUrgent() {
        return isUrgent;
    }

    public void setIsUrgent(Boolean isUrgent) {
        this.isUrgent = isUrgent;
    }
}
