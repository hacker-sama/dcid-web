package vn.dcid.dto.response;

import vn.dcid.domain.entity.GuestDocument;
import vn.dcid.domain.enums.GuestDocumentStatus;

import java.time.Instant;
import java.util.UUID;

public record GuestDocumentDTO(
        UUID id,
        UUID sessionId,
        String originalFilename,
        Long fileSize,
        GuestDocumentStatus status,
        Integer pageCount,
        String errorMessage,
        Instant createdAt,
        Instant expiresAt
) {
    public static GuestDocumentDTO from(GuestDocument d) {
        return new GuestDocumentDTO(
                d.getId(),
                d.getSessionId(),
                d.getOriginalFilename(),
                d.getFileSize(),
                d.getStatus(),
                d.getPageCount(),
                d.getErrorMessage(),
                d.getCreatedAt(),
                d.getExpiresAt()
        );
    }
}
