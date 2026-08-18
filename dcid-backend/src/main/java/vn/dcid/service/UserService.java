package vn.dcid.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.User;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.dto.request.ChangePasswordRequest;
import vn.dcid.dto.request.CreateUserRequest;
import vn.dcid.dto.request.ResetPasswordRequest;
import vn.dcid.dto.request.UpdateUserRequest;
import vn.dcid.dto.request.UpdateUserStatusRequest;
import vn.dcid.dto.response.UserProfileDTO;
import vn.dcid.exception.ConflictException;
import vn.dcid.exception.NotFoundException;
import vn.dcid.repository.UserRepository;
import vn.dcid.security.SecurityContextHelper;

import java.util.List;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuditLogService auditLogService;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       AuditLogService auditLogService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.auditLogService = auditLogService;
    }

    public User getCurrentUser() {
        String userId = SecurityContextHelper.getCurrentUserId();
        if (userId == null) {
            throw new NotFoundException("No authenticated user in context");
        }
        return getUserById(UUID.fromString(userId));
    }

    public User getUserById(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("User", id.toString()));
    }

    public User getUserByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new NotFoundException("User", username));
    }

    @Transactional(readOnly = true)
    public PagedResponse<UserProfileDTO> listUsers(int page, int size, UserRole role, String search) {
        PageRequest pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<User> usersPage = userRepository.searchUsers(role, search, pageable);
        List<UserProfileDTO> dtos = usersPage.getContent().stream()
                .map(this::toUserProfileDTO)
                .toList();
        return PagedResponse.of(dtos, usersPage.getNumber(), usersPage.getSize(), usersPage.getTotalElements());
    }

    @Transactional
    public UserProfileDTO createUser(CreateUserRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new ConflictException("Username '" + request.username() + "' is already taken");
        }

        User user = new User();
        user.setUsername(request.username());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setFullName(request.fullName());
        user.setEmail(request.email());
        user.setRole(request.role());
        user.setIsActive(true);

        User saved = userRepository.save(user);
        UUID actorId = currentActorId();
        auditLogService.log(actorId, "USER_CREATED", "USER", saved.getId(), null,
                "{\"username\":\"" + saved.getUsername() + "\",\"role\":\"" + saved.getRole().name() + "\"}");
        return toUserProfileDTO(saved);
    }

    @Transactional
    public UserProfileDTO updateUser(UUID id, UpdateUserRequest request) {
        User user = getUserById(id);
        UserRole oldRole = user.getRole();
        if (request.fullName() != null) {
            user.setFullName(request.fullName());
        }
        if (request.email() != null) {
            user.setEmail(request.email());
        }
        if (request.role() != null) {
            user.setRole(request.role());
        }
        User updated = userRepository.save(user);
        String detail = request.role() != null && !request.role().equals(oldRole)
                ? "{\"userId\":\"" + id + "\",\"oldRole\":\"" + oldRole.name() + "\",\"newRole\":\"" + updated.getRole().name() + "\"}"
                : "{\"userId\":\"" + id + "\"}";
        auditLogService.log(currentActorId(), "USER_UPDATED", "USER", id, null, detail);
        return toUserProfileDTO(updated);
    }

    @Transactional
    public void resetPassword(UUID id, ResetPasswordRequest request) {
        User user = getUserById(id);
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
        auditLogService.log(currentActorId(), "USER_PASSWORD_RESET", "USER", id, null,
                "{\"targetUserId\":\"" + id + "\"}");
    }

    @Transactional
    public void changeOwnPassword(ChangePasswordRequest request) {
        User user = getCurrentUser();
        if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new org.springframework.security.authentication.BadCredentialsException("Mật khẩu hiện tại không đúng");
        }
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
        auditLogService.log(user.getId(), "USER_SELF_PASSWORD_CHANGE", "USER", user.getId(), null, null);
    }

    @Transactional
    public UserProfileDTO updateUserStatus(UUID id, UpdateUserStatusRequest request) {
        User user = getUserById(id);
        boolean oldStatus = Boolean.TRUE.equals(user.getIsActive());
        user.setIsActive(request.isActive());
        User updated = userRepository.save(user);
        auditLogService.log(currentActorId(), "USER_STATUS_CHANGE", "USER", id, null,
                "{\"targetUserId\":\"" + id + "\",\"from\":" + oldStatus + ",\"to\":" + request.isActive() + "}");
        return toUserProfileDTO(updated);
    }

    /** Lấy actorId từ SecurityContext — null-safe (system task hoặc internal call). */
    private UUID currentActorId() {
        String id = SecurityContextHelper.getCurrentUserId();
        return id != null ? UUID.fromString(id) : null;
    }

    public UserProfileDTO toUserProfileDTO(User user) {
        return new UserProfileDTO(
                user.getId(),
                user.getUsername(),
                user.getFullName(),
                user.getEmail(),
                user.getRole().name(),
                user.getIsActive(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }
}
