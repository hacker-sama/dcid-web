package vn.dcid.dto.response;

public record LoginResponse(
        String token,
        String tokenType,
        long expiresInSeconds,
        String username,
        String role
) {
    public static LoginResponse bearer(String token, long expiresInSeconds, String username, String role) {
        return new LoginResponse(token, "Bearer", expiresInSeconds, username, role);
    }
}
