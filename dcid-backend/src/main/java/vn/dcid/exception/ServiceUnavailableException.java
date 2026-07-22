package vn.dcid.exception;

/** Dịch vụ phụ thuộc (AI service) không phản hồi — map sang HTTP 503. */
public class ServiceUnavailableException extends AppException {

    public ServiceUnavailableException(String message) {
        super("SERVICE_UNAVAILABLE", message);
    }

    public ServiceUnavailableException(String message, Throwable cause) {
        super("SERVICE_UNAVAILABLE", message, cause);
    }
}
