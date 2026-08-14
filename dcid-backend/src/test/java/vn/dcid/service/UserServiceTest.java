package vn.dcid.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.User;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.dto.request.CreateUserRequest;
import vn.dcid.dto.request.ResetPasswordRequest;
import vn.dcid.dto.request.UpdateUserRequest;
import vn.dcid.dto.request.UpdateUserStatusRequest;
import vn.dcid.dto.response.UserProfileDTO;
import vn.dcid.exception.ConflictException;
import vn.dcid.repository.UserRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    private User sampleUser;
    private UUID sampleId;

    @BeforeEach
    void setUp() {
        sampleId = UUID.randomUUID();
        sampleUser = new User();
        sampleUser.setId(sampleId);
        sampleUser.setUsername("testuser");
        sampleUser.setPasswordHash("hashedPassword");
        sampleUser.setFullName("Test User");
        sampleUser.setEmail("test@kcn.vn");
        sampleUser.setRole(UserRole.ENGINEER);
        sampleUser.setIsActive(true);
    }

    @Test
    void createUser_Success() {
        CreateUserRequest req = new CreateUserRequest("newuser", "pass123", "New User", "new@kcn.vn", UserRole.OPERATOR);
        when(userRepository.existsByUsername("newuser")).thenReturn(false);
        when(passwordEncoder.encode("pass123")).thenReturn("encodedPass");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });

        UserProfileDTO dto = userService.createUser(req);

        assertNotNull(dto);
        assertEquals("newuser", dto.username());
        assertEquals("OPERATOR", dto.role());
        verify(userRepository).save(any(User.class));
    }

    @Test
    void createUser_ConflictUsername() {
        CreateUserRequest req = new CreateUserRequest("existing", "pass123", "User", "email", UserRole.OPERATOR);
        when(userRepository.existsByUsername("existing")).thenReturn(true);

        assertThrows(ConflictException.class, () -> userService.createUser(req));
        verify(userRepository, never()).save(any());
    }

    @Test
    void listUsers_Success() {
        when(userRepository.searchUsers(eq(UserRole.ENGINEER), eq("test"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(sampleUser)));

        PagedResponse<UserProfileDTO> res = userService.listUsers(0, 10, UserRole.ENGINEER, "test");

        assertEquals(1, res.total());
        assertEquals(1, res.items().size());
        assertEquals("testuser", res.items().get(0).username());
    }

    @Test
    void updateUser_Success() {
        UpdateUserRequest req = new UpdateUserRequest("Updated Name", "updated@kcn.vn", UserRole.QA_ADMIN);
        when(userRepository.findById(sampleId)).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);

        UserProfileDTO dto = userService.updateUser(sampleId, req);

        assertEquals("Updated Name", dto.fullName());
        assertEquals("QA_ADMIN", dto.role());
    }

    @Test
    void resetPassword_Success() {
        ResetPasswordRequest req = new ResetPasswordRequest("newPass123");
        when(userRepository.findById(sampleId)).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.encode("newPass123")).thenReturn("newHashedPass");

        userService.resetPassword(sampleId, req);

        verify(userRepository).save(sampleUser);
        assertEquals("newHashedPass", sampleUser.getPasswordHash());
    }

    @Test
    void updateUserStatus_Success() {
        UpdateUserStatusRequest req = new UpdateUserStatusRequest(false);
        when(userRepository.findById(sampleId)).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);

        UserProfileDTO dto = userService.updateUserStatus(sampleId, req);

        assertFalse(dto.isActive());
    }
}
