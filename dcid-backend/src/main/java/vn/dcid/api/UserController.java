package vn.dcid.api;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.dto.request.CreateUserRequest;
import vn.dcid.dto.request.ResetPasswordRequest;
import vn.dcid.dto.request.UpdateUserRequest;
import vn.dcid.dto.request.UpdateUserStatusRequest;
import vn.dcid.dto.response.UserProfileDTO;
import vn.dcid.service.UserService;

import java.util.UUID;

@RestController
@RequestMapping("/api/admin/users")
@PreAuthorize("hasRole('ADMIN')")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<UserProfileDTO>>> listUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) UserRole role,
            @RequestParam(required = false) String search) {
        return ResponseEntity.ok(ApiResponse.of(userService.listUsers(page, size, role, search)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserProfileDTO>> createUser(@Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.of(userService.createUser(request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UserProfileDTO>> updateUser(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserRequest request) {
        return ResponseEntity.ok(ApiResponse.of(userService.updateUser(id, request)));
    }

    @PutMapping("/{id}/password")
    public ResponseEntity<ApiResponse<Boolean>> resetPassword(
            @PathVariable UUID id,
            @Valid @RequestBody ResetPasswordRequest request) {
        userService.resetPassword(id, request);
        return ResponseEntity.ok(ApiResponse.of(true));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<UserProfileDTO>> updateUserStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserStatusRequest request) {
        return ResponseEntity.ok(ApiResponse.of(userService.updateUserStatus(id, request)));
    }
}
