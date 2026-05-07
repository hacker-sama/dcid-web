package vn.dcid.api.officer;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.dto.request.CreateProcedureRequest;
import vn.dcid.dto.response.ProcedureDetailDTO;
import vn.dcid.dto.response.ProcedureTypeDTO;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/procedures")
public class AdminProcedureController {

    @PostMapping
    public ResponseEntity<ApiResponse<ProcedureTypeDTO>> createProcedure(@RequestBody CreateProcedureRequest request) {
        throw new UnsupportedOperationException("TODO: Implement create procedure");
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ProcedureTypeDTO>> updateProcedure(
            @PathVariable UUID id,
            @RequestBody CreateProcedureRequest request) {
        throw new UnsupportedOperationException("TODO: Implement update procedure");
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<ProcedureTypeDTO>>> getAllProcedures(Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get all procedures");
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProcedureDetailDTO>> getProcedure(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement get procedure");
    }

    @GetMapping("/active")
    public ResponseEntity<ApiResponse<List<ProcedureTypeDTO>>> getActiveProcedures() {
        throw new UnsupportedOperationException("TODO: Implement get active procedures");
    }

    @PostMapping("/{id}/activate")
    public ResponseEntity<ApiResponse<Void>> activateProcedure(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement activate procedure");
    }

    @PostMapping("/{id}/deactivate")
    public ResponseEntity<ApiResponse<Void>> deactivateProcedure(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement deactivate procedure");
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteProcedure(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement delete procedure");
    }
}
