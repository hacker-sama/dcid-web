package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record IngestStatusPushRequest(
    @NotNull UUID versionId,
    @NotBlank String step,
    int progress,
    String message
) {}
