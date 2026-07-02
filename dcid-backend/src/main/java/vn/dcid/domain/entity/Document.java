package vn.dcid.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import vn.dcid.common.AuditableEntity;
import vn.dcid.domain.enums.DocumentCategory;
import vn.dcid.domain.enums.UserRole;

/** Một tài liệu logic của 1 máy/loại thiết bị (có nhiều version). */
@Entity
@Table(name = "documents")
public class Document extends AuditableEntity {

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "machine_code", length = 100)
    private String machineCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 50)
    private DocumentCategory category;

    /** Vai tối thiểu được xem tài liệu này. */
    @Enumerated(EnumType.STRING)
    @Column(name = "min_role", nullable = false, length = 50)
    private UserRole minRole = UserRole.OPERATOR;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMachineCode() {
        return machineCode;
    }

    public void setMachineCode(String machineCode) {
        this.machineCode = machineCode;
    }

    public DocumentCategory getCategory() {
        return category;
    }

    public void setCategory(DocumentCategory category) {
        this.category = category;
    }

    public UserRole getMinRole() {
        return minRole;
    }

    public void setMinRole(UserRole minRole) {
        this.minRole = minRole;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
