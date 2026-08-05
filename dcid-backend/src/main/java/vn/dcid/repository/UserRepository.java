package vn.dcid.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.User;
import vn.dcid.domain.enums.UserRole;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByUsername(String username);

    boolean existsByUsername(String username);

    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE " +
           "(cast(:role as string) IS NULL OR u.role = :role) AND " +
           "(cast(:search as string) IS NULL OR cast(:search as string) = '' OR " +
           " LOWER(u.username) LIKE LOWER(CONCAT('%', cast(:search as string), '%')) OR " +
           " (u.fullName IS NOT NULL AND LOWER(u.fullName) LIKE LOWER(CONCAT('%', cast(:search as string), '%'))) OR " +
           " (u.email IS NOT NULL AND LOWER(u.email) LIKE LOWER(CONCAT('%', cast(:search as string), '%'))))")
    Page<User> searchUsers(@Param("role") UserRole role, @Param("search") String search, Pageable pageable);
}

