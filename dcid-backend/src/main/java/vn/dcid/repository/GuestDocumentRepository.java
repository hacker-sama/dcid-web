package vn.dcid.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.GuestDocument;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GuestDocumentRepository extends JpaRepository<GuestDocument, UUID> {

    List<GuestDocument> findBySessionId(UUID sessionId);

    Optional<GuestDocument> findByIdAndSessionId(UUID id, UUID sessionId);

    int countBySessionId(UUID sessionId);

    void deleteBySessionId(UUID sessionId);
}
