package vn.dcid.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import vn.dcid.domain.entity.ProcedureType;
import vn.dcid.dto.request.CreateProcedureRequest;
import vn.dcid.dto.response.ProcedureDetailDTO;
import vn.dcid.dto.response.ProcedureTypeDTO;
import vn.dcid.repository.ProcedureTypeRepository;

import java.util.List;
import java.util.UUID;

@Service
public class ProcedureService {

    private final ProcedureTypeRepository procedureTypeRepository;

    public ProcedureService(ProcedureTypeRepository procedureTypeRepository) {
        this.procedureTypeRepository = procedureTypeRepository;
    }

    public ProcedureTypeDTO createProcedure(CreateProcedureRequest request) {
        throw new UnsupportedOperationException("TODO: Implement create procedure");
    }

    public ProcedureTypeDTO updateProcedure(UUID id, CreateProcedureRequest request) {
        throw new UnsupportedOperationException("TODO: Implement update procedure");
    }

    public ProcedureDetailDTO getProcedure(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement get procedure");
    }

    public ProcedureDetailDTO getProcedureByCode(String code) {
        throw new UnsupportedOperationException("TODO: Implement get procedure by code");
    }

    public Page<ProcedureTypeDTO> getAllProcedures(Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get all procedures");
    }

    public List<ProcedureTypeDTO> getActiveProcedures() {
        throw new UnsupportedOperationException("TODO: Implement get active procedures");
    }

    public void deleteProcedure(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement delete procedure");
    }

    public void activateProcedure(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement activate procedure");
    }

    public void deactivateProcedure(UUID id) {
        throw new UnsupportedOperationException("TODO: Implement deactivate procedure");
    }
}
