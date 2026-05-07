package vn.dcid.common;

import java.util.List;

public record ErrorResponse(
        String code,
        String message,
        String traceId,
        List<ValidationError> errors
) {

    public static ErrorResponse of(String code, String message, String traceId) {
        return new ErrorResponse(code, message, traceId, null);
    }

    public static ErrorResponse of(String code, String message, String traceId, List<ValidationError> errors) {
        return new ErrorResponse(code, message, traceId, errors);
    }
}
