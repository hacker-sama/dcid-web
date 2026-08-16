package vn.dcid.service;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import vn.dcid.domain.entity.User;
import vn.dcid.dto.request.LoginRequest;
import vn.dcid.dto.response.LoginResponse;
import vn.dcid.repository.UserRepository;
import vn.dcid.security.JwtService;

/**
 * Handles credential verification and access-token issuance for the on-premise JWT flow.
 */
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuditLogService auditLogService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       JwtService jwtService, AuditLogService auditLogService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.auditLogService = auditLogService;
    }

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.username())
                .filter(u -> Boolean.TRUE.equals(u.getIsActive()))
                .filter(u -> passwordEncoder.matches(request.password(), u.getPasswordHash()))
                // Same error for unknown user / bad password / inactive account (avoid user enumeration).
                .orElseThrow(() -> new BadCredentialsException("Invalid username or password"));

        String token = jwtService.issueToken(user);
        auditLogService.log(user.getId(), "USER_LOGIN", "USER", user.getId(), resolveClientIp(), null);
        return LoginResponse.bearer(token, jwtService.getExpirationSeconds(),
                user.getUsername(), user.getRole().name());
    }

    /** Trích IP client từ request hiện tại — ưu tiên X-Forwarded-For (proxy/nginx). */
    private String resolveClientIp() {
        try {
            ServletRequestAttributes attrs =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs == null) return null;
            HttpServletRequest req = attrs.getRequest();
            String forwarded = req.getHeader("X-Forwarded-For");
            if (forwarded != null && !forwarded.isBlank()) {
                return forwarded.split(",")[0].trim();
            }
            return req.getRemoteAddr();
        } catch (Exception e) {
            return null;
        }
    }
}
