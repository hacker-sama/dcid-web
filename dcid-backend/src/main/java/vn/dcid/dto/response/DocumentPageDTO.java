package vn.dcid.dto.response;

import vn.dcid.domain.entity.DocumentPage;
import java.util.UUID;

public record DocumentPageDTO(
        UUID id,
        Integer pageNo,
        Integer width,
        Integer height,
        String ocrText
) {
    public static DocumentPageDTO from(DocumentPage p) {
        return new DocumentPageDTO(
                p.getId(),
                p.getPageNo(),
                p.getWidth(),
                p.getHeight(),
                p.getOcrText()
        );
    }
}
