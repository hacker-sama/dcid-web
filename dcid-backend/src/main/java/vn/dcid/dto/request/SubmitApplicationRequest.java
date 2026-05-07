package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.Map;

public record SubmitApplicationRequest(
        @NotNull(message = "Procedure type ID is required")
        java.util.UUID procedureTypeId,

        @NotNull(message = "Form data is required")
        Map<String, Object> formData,

        @Size(max = 1000, message = "Notes must not exceed 1000 characters")
        String notes,

        Boolean isUrgent
) {
}
