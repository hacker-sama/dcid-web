package vn.dcid.service;

import org.springframework.stereotype.Service;
import vn.dcid.domain.entity.User;
import vn.dcid.exception.NotFoundException;
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
}
