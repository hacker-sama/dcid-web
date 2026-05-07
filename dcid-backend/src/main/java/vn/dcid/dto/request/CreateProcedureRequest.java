package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.Map;

public record CreateProcedureRequest(
        @NotBlank(message = "Code is required")
        @Size(max = 100, message = "Code must not exceed 100 characters")
        String code,

        @NotBlank(message = "Name is required")
        @Size(max = 255, message = "Name must not exceed 255 characters")
        String name,

        @Size(max = 2000, message = "Description must not exceed 2000 characters")
        String description,

        @NotNull(message = "JSON schema is required")
        String jsonSchema,

        @NotNull(message = "Estimated days is required")
        Integer estimatedDays,

        java.math.BigDecimal fee
) {
}
