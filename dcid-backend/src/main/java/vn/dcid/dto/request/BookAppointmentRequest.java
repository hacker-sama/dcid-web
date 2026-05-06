package vn.dcid.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public record BookAppointmentRequest(
        @NotNull(message = "Scheduled at is required")
        Instant scheduledAt,

        Integer durationMinutes,

        @Size(max = 255, message = "Location must not exceed 255 characters")
        String location,

        @Size(max = 1000, message = "Notes must not exceed 1000 characters")
        String notes
) {
}
