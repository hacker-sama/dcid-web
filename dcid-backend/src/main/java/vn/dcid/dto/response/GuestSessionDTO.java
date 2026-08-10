package vn.dcid.dto.response;

import vn.dcid.domain.entity.GuestSession;
import vn.dcid.domain.enums.SessionStatus;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record GuestSessionDTO(
        UUID id,
        SessionStatus status,
        Instant createdAt,
        Instant expiresAt,
        Integer documentCount,
        Long totalSize,
        List<GuestDocumentDTO> documents
) {
    public static GuestSessionDTO from(GuestSession session, List<GuestDocumentDTO> docs) {
        return new GuestSessionDTO(
                session.getId(),
                session.getStatus(),
                session.getCreatedAt(),
                session.getExpiresAt(),
                session.getDocumentCount(),
                session.getTotalSize(),
                docs
        );
    }
}
