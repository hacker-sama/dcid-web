package vn.dcid.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.QueryLog;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface QueryLogRepository extends JpaRepository<QueryLog, UUID> {

    Page<QueryLog> findByActorIdOrderByCreatedAtDesc(UUID actorId, Pageable pageable);

    java.util.Optional<QueryLog> findByIdAndActorId(UUID id, UUID actorId);

    void deleteByActorId(UUID actorId);

    void deleteByIdAndActorId(UUID id, UUID actorId);

    long countByLocked(boolean locked);

    long countByNumericRuleHit(boolean numericRuleHit);

    @Query("SELECT AVG(q.confidence) FROM QueryLog q WHERE q.confidence IS NOT NULL")
    Double calculateAvgConfidence();

    @Query("SELECT AVG(q.latencyMs) FROM QueryLog q WHERE q.latencyMs IS NOT NULL")
    Double calculateAvgLatencyMs();

    @Query("SELECT q FROM QueryLog q WHERE q.createdAt >= :since ORDER BY q.createdAt ASC")
    List<QueryLog> findQueriesSince(@Param("since") Instant since);

    @Query("SELECT q FROM QueryLog q WHERE q.feedback IS NOT NULL " +
           "AND (:feedback IS NULL OR q.feedback = :feedback) " +
           "ORDER BY COALESCE(q.feedbackAt, q.createdAt) DESC")
    Page<QueryLog> findFeedbacks(@Param("feedback") Short feedback, Pageable pageable);
}
