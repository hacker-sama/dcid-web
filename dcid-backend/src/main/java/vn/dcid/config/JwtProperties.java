package vn.dcid.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Configuration for the self-issued JWT (bound from {@code app.jwt.*}).
 *
 * @param secret         HMAC-SHA256 signing secret; MUST be >= 32 bytes. Override per environment.
 * @param expirationMs   access-token lifetime in milliseconds.
 * @param issuer         the {@code iss} claim written into issued tokens.
 */
@ConfigurationProperties(prefix = "app.jwt")
public record JwtProperties(
        String secret,
        long expirationMs,
        String issuer
) {
}
