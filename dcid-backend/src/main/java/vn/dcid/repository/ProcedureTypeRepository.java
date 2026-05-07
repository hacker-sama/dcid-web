package vn.dcid.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.ProcedureType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProcedureTypeRepository extends JpaRepository<ProcedureType, UUID> {

    Optional<ProcedureType> findByCode(String code);

    List<ProcedureType> findByIsActiveTrue();

    boolean existsByCode(String code);
}
