package vn.dcid.exception;

public class NotFoundException extends AppException {

    public NotFoundException(String message) {
        super("NOT_FOUND", message);
    }

    public NotFoundException(String resource, String identifier) {
        super("NOT_FOUND", String.format("%s not found: %s", resource, identifier));
    }
}
