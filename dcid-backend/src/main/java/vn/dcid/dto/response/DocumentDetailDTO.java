package vn.dcid.dto.response;

import java.util.List;

public record DocumentDetailDTO(
        DocumentDTO document,
        List<DocumentVersionDTO> versions
) {
}
