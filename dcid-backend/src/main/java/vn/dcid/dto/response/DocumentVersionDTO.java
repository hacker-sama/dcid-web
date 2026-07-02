package vn.dcid.dto.response;

import vn.dcid.domain.entity.DocumentVersion;
import vn.dcid.domain.enums.VersionStatus;

import java.time.Instant;
import java.util.UUID;

public record DocumentVersionDTO(
        UUID id,
        UUID documentId,
        Integer versionNo,
        VersionStatus status,
        String lang,
        Integer pageCount,
        String originalFilename,
        Long fileSize,
        Instant createdAt,
        Instant ingestedAt
) {
    public static DocumentVersionDTO from(DocumentVersion v) {
        return new DocumentVersionDTO(
                v.getId(),
                v.getDocumentId(),
                v.getVersionNo(),
                v.getStatus(),
                v.getLang(),
                v.getPageCount(),
                v.getOriginalFilename(),
                v.getFileSize(),
                v.getCreatedAt(),
                v.getIngestedAt()
        );
    }
}
