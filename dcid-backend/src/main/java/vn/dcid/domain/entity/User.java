package vn.dcid.domain.entity;

import jakarta.persistence.*;
import vn.dcid.common.AuditableEntity;
import vn.dcid.domain.enums.UserRole;

import java.util.UUID;

@Entity
@Table(name = "users")
public class User extends AuditableEntity {

    @Column(name = "keycloak_id", unique = true, nullable = false, length = 255)
    private String keycloakId;

    @Column(name = "email", nullable = false, length = 255)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 50)
    private UserRole role;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    public String getKeycloakId() {
        return keycloakId;
    }

    public void setKeycloakId(String keycloakId) {
        this.keycloakId = keycloakId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public UserRole getRole() {
        return role;
    }

    public void setRole(UserRole role) {
        this.role = role;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }
}
