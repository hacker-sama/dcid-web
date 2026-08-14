package vn.dcid.dto.response;

import java.util.UUID;

public record IngestProgressMessage(
    UUID versionId,
    String step,
    int progress,
    String message
) {}
