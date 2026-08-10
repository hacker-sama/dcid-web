package vn.dcid.dto.response;

import vn.dcid.domain.entity.GuestDocument;
import vn.dcid.domain.enums.VersionStatus;

import java.time.Instant;
import java.util.UUID;

public record GuestDocumentDTO(
        UUID id,
        UUID sessionId,
        String originalFilename,
        Long fileSize,
        VersionStatus status,
        Integer pageCount,
        String errorMessage,
        Instant createdAt
) {
    public static GuestDocumentDTO from(GuestDocument doc) {
        return new GuestDocumentDTO(
                doc.getId(),
                doc.getSessionId(),
                doc.getOriginalFilename(),
                doc.getFileSize(),
                doc.getStatus(),
                doc.getPageCount(),
                doc.getErrorMessage(),
                doc.getCreatedAt()
        );
    }
}
