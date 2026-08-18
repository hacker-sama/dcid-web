package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record GuestQueryRequest(
        @NotBlank(message = "question is required")
        @Size(max = 2000, message = "question is too long")
        String question
) {}
