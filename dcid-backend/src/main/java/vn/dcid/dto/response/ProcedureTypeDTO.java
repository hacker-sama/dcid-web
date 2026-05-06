package vn.dcid.dto.response;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ProcedureTypeDTO(
        UUID id,
        String code,
        String name,
        String description,
        Integer estimatedDays,
        BigDecimal fee,
        Boolean isActive,
        Instant createdAt,
        Instant updatedAt
) {
}
