package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import vn.dcid.domain.enums.UserRole;

public record CreateUserRequest(
        @NotBlank @Size(min = 3, max = 100) String username,
        @NotBlank @Size(min = 6, max = 100) String password,
        String fullName,
        String email,
        @NotNull UserRole role
) {}
