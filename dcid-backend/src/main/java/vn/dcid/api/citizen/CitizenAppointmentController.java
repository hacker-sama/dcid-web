package vn.dcid.api.citizen;

import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.dto.request.BookAppointmentRequest;
import vn.dcid.dto.response.AppointmentDTO;

import java.util.UUID;

@RestController
@RequestMapping("/api/citizens/appointments")
public class CitizenAppointmentController {

    @PostMapping("/{applicationId}")
    public ResponseEntity<ApiResponse<AppointmentDTO>> bookAppointment(
            @PathVariable UUID applicationId,
            @RequestBody BookAppointmentRequest request) {
        // TODO: Implement book appointment
        throw new UnsupportedOperationException("TODO: Implement book appointment");
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<AppointmentDTO>>> getMyAppointments(Pageable pageable) {
        // TODO: Implement get my appointments
        throw new UnsupportedOperationException("TODO: Implement get my appointments");
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AppointmentDTO>> getAppointment(@PathVariable UUID id) {
        // TODO: Implement get appointment
        throw new UnsupportedOperationException("TODO: Implement get appointment");
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Void>> cancelAppointment(@PathVariable UUID id) {
        // TODO: Implement cancel appointment
        throw new UnsupportedOperationException("TODO: Implement cancel appointment");
    }
}
