package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public record ReviewApplicationRequest(
        @NotBlank(message = "Action is required")
        String action,

        @Size(max = 2000, message = "Note must not exceed 2000 characters")
        String note,

        List<String> missingDocs
) {
}
