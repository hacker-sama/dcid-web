package vn.dcid.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.Application;
import vn.dcid.domain.enums.ApplicationStatus;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ApplicationRepository extends JpaRepository<Application, UUID> {

    Page<Application> findByApplicantId(UUID applicantId, Pageable pageable);

    Page<Application> findByAssignedOfficerIdAndStatus(UUID assignedOfficerId, ApplicationStatus status, Pageable pageable);

    long countByApplicantIdAndStatus(UUID applicantId, ApplicationStatus status);

    @Query("SELECT a FROM Application a WHERE a.status = :status AND a.estimatedCompletionAt < :now")
    List<Application> findOverdue(@Param("status") ApplicationStatus status, @Param("now") Instant now);

    Optional<Application> findByIdAndApplicantId(UUID id, UUID applicantId);

    Optional<Application> findByIdAndAssignedOfficerId(UUID id, UUID assignedOfficerId);
}
