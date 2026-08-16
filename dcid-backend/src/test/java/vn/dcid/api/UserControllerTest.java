package vn.dcid.api;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.dto.request.CreateUserRequest;
import vn.dcid.dto.request.ResetPasswordRequest;
import vn.dcid.dto.request.UpdateUserRequest;
import vn.dcid.dto.request.UpdateUserStatusRequest;
import vn.dcid.dto.response.UserProfileDTO;
import vn.dcid.service.UserService;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UserControllerTest {

    @Mock
    private UserService userService;

    @InjectMocks
    private UserController userController;

    private UserProfileDTO sampleDto;
    private UUID sampleId;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        sampleId = UUID.randomUUID();
        sampleDto = new UserProfileDTO(
                sampleId,
                "adminuser",
                "Admin User",
                "admin@kcn.vn",
                "ADMIN",
                true,
                Instant.now(),
                Instant.now()
        );
    }

    @Test
    void listUsers_ReturnsPagedResponse() {
        PagedResponse<UserProfileDTO> paged = PagedResponse.of(List.of(sampleDto), 0, 20, 1);
        when(userService.listUsers(0, 20, UserRole.ADMIN, "admin")).thenReturn(paged);

        ResponseEntity<ApiResponse<PagedResponse<UserProfileDTO>>> response =
                userController.listUsers(0, 20, UserRole.ADMIN, "admin");

        assertNotNull(response.getBody());
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(1, response.getBody().data().total());
    }

    @Test
    void createUser_ReturnsCreatedStatus() {
        CreateUserRequest req = new CreateUserRequest("adminuser", "Password123!", "Admin User", "admin@kcn.vn", UserRole.ADMIN);
        when(userService.createUser(req)).thenReturn(sampleDto);

        ResponseEntity<ApiResponse<UserProfileDTO>> response = userController.createUser(req);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("adminuser", response.getBody().data().username());
    }

    @Test
    void updateUser_ReturnsOkStatus() {
        UpdateUserRequest req = new UpdateUserRequest("Admin Updated", "admin@kcn.vn", UserRole.ADMIN);
        when(userService.updateUser(eq(sampleId), eq(req))).thenReturn(sampleDto);

        ResponseEntity<ApiResponse<UserProfileDTO>> response = userController.updateUser(sampleId, req);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
    }

    @Test
    void resetPassword_ReturnsOkStatus() {
        ResetPasswordRequest req = new ResetPasswordRequest("NewPassword123!");

        ResponseEntity<ApiResponse<Boolean>> response = userController.resetPassword(sampleId, req);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().data());
        verify(userService).resetPassword(sampleId, req);
    }

    @Test
    void updateUserStatus_ReturnsOkStatus() {
        UpdateUserStatusRequest req = new UpdateUserStatusRequest(false);
        when(userService.updateUserStatus(eq(sampleId), eq(req))).thenReturn(sampleDto);

        ResponseEntity<ApiResponse<UserProfileDTO>> response = userController.updateUserStatus(sampleId, req);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
    }
}
