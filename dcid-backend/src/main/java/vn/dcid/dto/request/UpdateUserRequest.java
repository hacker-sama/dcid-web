package vn.dcid.dto.request;

import jakarta.validation.constraints.NotNull;
import vn.dcid.domain.enums.UserRole;

public record UpdateUserRequest(
        String fullName,
        String email,
        @NotNull UserRole role
) {}
