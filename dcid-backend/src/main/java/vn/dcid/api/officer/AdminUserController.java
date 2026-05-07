package vn.dcid.api.officer;

import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.dto.response.UserProfileDTO;

import java.util.UUID;

@RestController
@RequestMapping("/api/admin/users")
public class AdminUserController {

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<UserProfileDTO>>> getAllUsers(Pageable pageable) {
        // TODO: Implement get all users
        throw new UnsupportedOperationException("TODO: Implement get all users");
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserProfileDTO>> getUser(@PathVariable UUID id) {
        // TODO: Implement get user by id
        throw new UnsupportedOperationException("TODO: Implement get user by id");
    }

    @PostMapping("/{id}/activate")
    public ResponseEntity<ApiResponse<Void>> activateUser(@PathVariable UUID id) {
        // TODO: Implement activate user
        throw new UnsupportedOperationException("TODO: Implement activate user");
    }

    @PostMapping("/{id}/deactivate")
    public ResponseEntity<ApiResponse<Void>> deactivateUser(@PathVariable UUID id) {
        // TODO: Implement deactivate user
        throw new UnsupportedOperationException("TODO: Implement deactivate user");
    }

    @PutMapping("/{id}/role")
    public ResponseEntity<ApiResponse<UserProfileDTO>> updateUserRole(
            @PathVariable UUID id,
            @RequestParam String role) {
        // TODO: Implement update user role
        throw new UnsupportedOperationException("TODO: Implement update user role");
    }
}
