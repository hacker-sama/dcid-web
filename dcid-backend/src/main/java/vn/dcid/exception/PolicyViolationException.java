package vn.dcid.exception;

public class PolicyViolationException extends AppException {

    public PolicyViolationException(String message) {
        super("POLICY_VIOLATION", message);
    }
}
