package vn.dcid.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.Appointment;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, UUID> {

    Page<Appointment> findByCitizenIdOrderByScheduledAtDesc(UUID citizenId, Pageable pageable);

    Page<Appointment> findByOfficerIdOrderByScheduledAtDesc(UUID officerId, Pageable pageable);

    List<Appointment> findByApplicationId(UUID applicationId);

    List<Appointment> findByOfficerIdAndScheduledAtBetween(UUID officerId, Instant start, Instant end);

    List<Appointment> findByCitizenIdAndScheduledAtAfterAndStatus(UUID citizenId, Instant after, String status);
}
