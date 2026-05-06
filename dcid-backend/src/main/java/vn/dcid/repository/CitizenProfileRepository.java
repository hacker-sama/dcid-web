package vn.dcid.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.CitizenProfile;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CitizenProfileRepository extends JpaRepository<CitizenProfile, UUID> {

    Optional<CitizenProfile> findByUserId(UUID userId);

    Optional<CitizenProfile> findByIdNumber(String idNumber);

    boolean existsByUserId(UUID userId);

    boolean existsByIdNumber(String idNumber);
}
