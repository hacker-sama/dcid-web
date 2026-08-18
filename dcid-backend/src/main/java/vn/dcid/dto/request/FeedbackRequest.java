package vn.dcid.dto.request;

import jakarta.validation.constraints.NotNull;

public record FeedbackRequest(
        @NotNull Boolean helpful,
        String note
) {}
