package vn.dcid.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Set;

public class SecurityContextHelper {

    public static UserPrincipal getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        return (UserPrincipal) authentication.getPrincipal();
    }

    public static String getCurrentUserId() {
        UserPrincipal principal = getCurrentUser();
        return principal != null ? principal.userId() : null;
    }

    public static String getCurrentRole() {
        UserPrincipal principal = getCurrentUser();
        return principal != null ? principal.role() : null;
    }

    public static Set<String> getCurrentRoles() {
        UserPrincipal principal = getCurrentUser();
        return principal != null ? principal.roles() : Set.of();
    }

    public static boolean hasRole(String role) {
        return getCurrentRoles().contains(role.toUpperCase());
    }

    public static boolean hasAnyRole(String... roles) {
        Set<String> currentRoles = getCurrentRoles();
        for (String role : roles) {
            if (currentRoles.contains(role.toUpperCase())) {
                return true;
            }
        }
        return false;
    }
}
