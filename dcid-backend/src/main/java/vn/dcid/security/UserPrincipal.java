package vn.dcid.security;

import java.util.Set;

/**
 * Authenticated principal extracted from the self-issued JWT.
 *
 * @param userId   the user's UUID (JWT subject)
 * @param username the login name
 * @param role     the primary role name (e.g. {@code ENGINEER})
 * @param roles    all role names granted to the user
 */
public record UserPrincipal(
        String userId,
        String username,
        String role,
        Set<String> roles
) {
}
