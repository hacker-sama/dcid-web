package vn.dcid.api;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.common.ApiResponse;
import vn.dcid.domain.entity.User;
import vn.dcid.dto.request.LoginRequest;
import vn.dcid.dto.response.LoginResponse;
import vn.dcid.dto.response.UserProfileDTO;
import vn.dcid.service.AuthService;
import vn.dcid.service.UserService;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final UserService userService;

    public AuthController(AuthService authService, UserService userService) {
        this.authService = authService;
        this.userService = userService;
    }

    /** Verifies credentials and returns a self-issued JWT. Public endpoint. */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.of(authService.login(request)));
    }

    /** Returns the profile of the currently authenticated user. */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileDTO>> getCurrentUser() {
        User user = userService.getCurrentUser();
        UserProfileDTO dto = new UserProfileDTO(
                user.getId(),
                user.getUsername(),
                user.getFullName(),
                user.getEmail(),
                user.getRole().name(),
                user.getIsActive(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
        return ResponseEntity.ok(ApiResponse.of(dto));
    }
}
