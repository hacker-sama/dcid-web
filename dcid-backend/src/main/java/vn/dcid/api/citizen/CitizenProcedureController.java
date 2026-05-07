package vn.dcid.api.citizen;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.dto.response.ProcedureDetailDTO;
import vn.dcid.dto.response.ProcedureTypeDTO;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/citizens/procedures")
public class CitizenProcedureController {

    @GetMapping
    public ResponseEntity<ApiResponse<List<ProcedureTypeDTO>>> getActiveProcedures() {
        // TODO: Implement get active procedures for citizens
        throw new UnsupportedOperationException("TODO: Implement get active procedures");
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProcedureDetailDTO>> getProcedure(@PathVariable UUID id) {
        // TODO: Implement get procedure detail
        throw new UnsupportedOperationException("TODO: Implement get procedure detail");
    }

    @GetMapping("/code/{code}")
    public ResponseEntity<ApiResponse<ProcedureDetailDTO>> getProcedureByCode(@PathVariable String code) {
        // TODO: Implement get procedure by code
        throw new UnsupportedOperationException("TODO: Implement get procedure by code");
    }
}
