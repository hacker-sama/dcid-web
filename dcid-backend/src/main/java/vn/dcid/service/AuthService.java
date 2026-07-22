package vn.dcid.service;

import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
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

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.username())
                .filter(u -> Boolean.TRUE.equals(u.getIsActive()))
                .filter(u -> passwordEncoder.matches(request.password(), u.getPasswordHash()))
                // Same error for unknown user / bad password / inactive account (avoid user enumeration).
                .orElseThrow(() -> new BadCredentialsException("Invalid username or password"));

        String token = jwtService.issueToken(user);
        return LoginResponse.bearer(token, jwtService.getExpirationSeconds(),
                user.getUsername(), user.getRole().name());
    }
}
