package vn.dcid.dto.response;

import java.util.UUID;

/** Snapshot returned while a Snap & Ask image is processed in the background. */
public record VisionJobDTO(
        UUID jobId,
        String status,
        String stage,
        AnswerDTO result,
        String error
) {
}
