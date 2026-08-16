package vn.dcid.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.GuestSession;
import vn.dcid.domain.enums.GuestSessionStatus;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GuestSessionRepository extends JpaRepository<GuestSession, UUID> {

    Optional<GuestSession> findBySessionTokenHash(String sessionTokenHash);

    List<GuestSession> findByStatusAndExpiresAtBefore(GuestSessionStatus status, Instant now);

    List<GuestSession> findByStatusAndDeletedAtIsNull(GuestSessionStatus status);
}
