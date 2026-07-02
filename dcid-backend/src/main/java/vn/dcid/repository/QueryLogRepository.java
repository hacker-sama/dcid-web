package vn.dcid.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.QueryLog;

import java.util.UUID;

@Repository
public interface QueryLogRepository extends JpaRepository<QueryLog, UUID> {

    Page<QueryLog> findByActorIdOrderByCreatedAtDesc(UUID actorId, Pageable pageable);
}
