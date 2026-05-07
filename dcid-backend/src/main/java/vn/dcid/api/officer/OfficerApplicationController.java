package vn.dcid.api.officer;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.dto.request.ReviewApplicationRequest;
import vn.dcid.dto.request.UpdateApplicationRequest;
import vn.dcid.dto.response.ApplicationDTO;
import vn.dcid.dto.response.ApplicationDetailDTO;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/officers/applications")
public class OfficerApplicationController {

    @GetMapping("/assigned")
    public ResponseEntity<ApiResponse<PagedResponse<ApplicationDTO>>> getAssignedApplications(
            @RequestParam(required = false) String status,
            Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get assigned applications");
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ApplicationDetailDTO>> getApplication(@PathVariable UUID id) {
        throw new UnsupportedOperationException("TODO: Implement get application");
    }

    @PostMapping("/{id}/review")
    public ResponseEntity<ApiResponse<ApplicationDTO>> reviewApplication(
            @PathVariable UUID id,
            @RequestBody ReviewApplicationRequest request) {
        throw new UnsupportedOperationException("TODO: Implement review application");
    }

    @PostMapping("/{id}/assign")
    public ResponseEntity<ApiResponse<ApplicationDTO>> assignOfficer(
            @PathVariable UUID id,
            @RequestParam UUID officerId) {
        throw new UnsupportedOperationException("TODO: Implement assign officer");
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ApplicationDTO>> updateApplication(
            @PathVariable UUID id,
            @RequestBody UpdateApplicationRequest request) {
        throw new UnsupportedOperationException("TODO: Implement update application");
    }

    @GetMapping("/overdue")
    public ResponseEntity<ApiResponse<List<ApplicationDTO>>> getOverdueApplications() {
        throw new UnsupportedOperationException("TODO: Implement get overdue applications");
    }
}
