package vn.dcid.api.citizen;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.dto.request.SubmitApplicationRequest;
import vn.dcid.dto.request.UpdateApplicationRequest;
import vn.dcid.dto.response.ApplicationDTO;
import vn.dcid.dto.response.ApplicationDetailDTO;

import java.util.UUID;

@RestController
@RequestMapping("/api/citizens/applications")
public class CitizenApplicationController {

    @PostMapping
    public ResponseEntity<ApiResponse<ApplicationDTO>> createDraft(@RequestBody SubmitApplicationRequest request) {
        throw new UnsupportedOperationException("TODO: Implement create draft");
    }

    @PostMapping("/{id}/submit")
    public ResponseEntity<ApiResponse<ApplicationDTO>> submitApplication(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement submit application");
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<ApplicationDTO>>> getMyApplications(Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get my applications");
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ApplicationDetailDTO>> getApplication(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement get application");
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ApplicationDTO>> updateApplication(
            @PathVariable UUID id,
            @RequestBody UpdateApplicationRequest request) {
        throw new UnsupportedOperationException("TODO: Implement update application");
    }

    @PostMapping("/{id}/withdraw")
    public ResponseEntity<ApiResponse<ApplicationDTO>> withdrawApplication(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement withdraw application");
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteApplication(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement delete application");
    }
}
