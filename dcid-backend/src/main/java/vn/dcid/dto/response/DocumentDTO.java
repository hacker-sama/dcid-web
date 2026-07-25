package vn.dcid.dto.response;

import vn.dcid.domain.entity.Document;
import vn.dcid.domain.enums.DocumentCategory;
import vn.dcid.domain.enums.UserRole;

import java.time.Instant;
import java.util.UUID;

public record DocumentDTO(
        UUID id,
        String title,
        String machineCode,
        DocumentCategory category,
        UserRole minRole,
        String description,
        Instant createdAt,
        Instant updatedAt
) {
    public static DocumentDTO from(Document d) {
        return new DocumentDTO(
                d.getId(),
                d.getTitle(),
                d.getMachineCode(),
                d.getCategory(),
                d.getMinRole(),
                d.getDescription(),
                d.getCreatedAt(),
                d.getUpdatedAt()
        );
    }
}
