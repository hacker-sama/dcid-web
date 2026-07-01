package vn.dcid.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;
import vn.dcid.config.JwtProperties;
import vn.dcid.domain.entity.User;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;

/**
 * Issues and validates self-signed (HMAC) JWTs. Fully on-premise — no external IdP.
 */
@Service
public class JwtService {

    private final JwtProperties properties;
    private final SecretKey key;

    public JwtService(JwtProperties properties) {
        this.properties = properties;
        this.key = Keys.hmacShaKeyFor(properties.secret().getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Issues an access token for the given user. Subject is the user id;
     * {@code username} and {@code role} are carried as custom claims.
     */
    public String issueToken(User user) {
        Instant now = Instant.now();
        Instant expiry = now.plusMillis(properties.expirationMs());
        return Jwts.builder()
                .issuer(properties.issuer())
                .subject(user.getId().toString())
                .claim("username", user.getUsername())
                .claim("role", user.getRole().name())
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(key)
                .compact();
    }

    /**
     * Parses and verifies a token, returning its claims.
     *
     * @throws io.jsonwebtoken.JwtException if the token is invalid, expired or tampered with.
     */
    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public long getExpirationSeconds() {
        return properties.expirationMs() / 1000;
    }
}
