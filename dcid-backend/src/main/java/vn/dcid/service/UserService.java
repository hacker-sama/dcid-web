package vn.dcid.service;

import org.springframework.stereotype.Service;
import vn.dcid.domain.entity.User;
import vn.dcid.repository.UserRepository;
import vn.dcid.security.SecurityContextHelper;

import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User getCurrentUser() {
        String userId = SecurityContextHelper.getCurrentUserId();
        if (userId == null) {
            throw new UnsupportedOperationException("TODO: User not authenticated");
        }
        return userRepository.findById(UUID.fromString(userId))
                .orElseThrow(() -> new UnsupportedOperationException("TODO: User not found"));
    }

    public User getUserById(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new UnsupportedOperationException("TODO: User not found"));
    }

    public User getUserByKeycloakId(String keycloakId) {
        return userRepository.findByKeycloakId(keycloakId)
                .orElseThrow(() -> new UnsupportedOperationException("TODO: User not found"));
    }
}
