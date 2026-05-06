package vn.dcid.exception;

public class ForbiddenException extends AppException {

    public ForbiddenException(String message) {
        super("FORBIDDEN", message);
    }
}
