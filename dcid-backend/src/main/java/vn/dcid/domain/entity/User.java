package vn.dcid.domain.entity;

import jakarta.persistence.*;
import vn.dcid.common.AuditableEntity;
import vn.dcid.domain.enums.UserRole;

/**
 * Application user, authenticated by a self-issued JWT (no external IdP).
 * Credentials are stored on-premise: {@code passwordHash} is a BCrypt hash.
 */
@Entity
@Table(name = "users")
public class User extends AuditableEntity {

    @Column(name = "username", unique = true, nullable = false, length = 100)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Column(name = "full_name", length = 255)
    private String fullName;

    @Column(name = "email", length = 255)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 50)
    private UserRole role;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
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
