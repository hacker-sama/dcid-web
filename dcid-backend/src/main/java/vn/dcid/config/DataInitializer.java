package vn.dcid.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import vn.dcid.domain.entity.User;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.repository.UserRepository;

/**
 * Seeds a bootstrap ADMIN account on first start (only when the users table is empty),
 * so the on-premise deployment has an initial login. Change the password immediately in production.
 */
@Component
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.bootstrap.admin-username:admin}")
    private String adminUsername;

    @Value("${app.bootstrap.admin-password:admin123}")
    private String adminPassword;

    public DataInitializer(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) {
            return;
        }
        User admin = new User();
        admin.setUsername(adminUsername);
        admin.setPasswordHash(passwordEncoder.encode(adminPassword));
        admin.setFullName("Bootstrap Administrator");
        admin.setRole(UserRole.ADMIN);
        admin.setIsActive(true);
        userRepository.save(admin);
        log.warn("Seeded bootstrap ADMIN user '{}'. CHANGE THE PASSWORD before production use.", adminUsername);
    }
}
