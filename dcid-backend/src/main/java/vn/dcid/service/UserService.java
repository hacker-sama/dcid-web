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

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
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
        return toUserProfileDTO(saved);
    }

    @Transactional
    public UserProfileDTO updateUser(UUID id, UpdateUserRequest request) {
        User user = getUserById(id);
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
        return toUserProfileDTO(updated);
    }

    @Transactional
    public void resetPassword(UUID id, ResetPasswordRequest request) {
        User user = getUserById(id);
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }

    @Transactional
    public UserProfileDTO updateUserStatus(UUID id, UpdateUserStatusRequest request) {
        User user = getUserById(id);
        user.setIsActive(request.isActive());
        User updated = userRepository.save(user);
        return toUserProfileDTO(updated);
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
