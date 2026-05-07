package vn.dcid.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.OfficerProfile;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface OfficerProfileRepository extends JpaRepository<OfficerProfile, UUID> {

    Optional<OfficerProfile> findByUserId(UUID userId);

    Optional<OfficerProfile> findByEmployeeCode(String employeeCode);

    boolean existsByUserId(UUID userId);

    boolean existsByEmployeeCode(String employeeCode);
}
