package vn.dcid.security;

import java.util.Set;

public record UserPrincipal(
        String userId,
        String email,
        String role,
        Set<String> roles
) {
}
