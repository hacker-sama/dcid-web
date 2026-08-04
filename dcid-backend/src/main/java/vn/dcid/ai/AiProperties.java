package vn.dcid.ai;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Cấu hình kết nối tới dcid-ai (bind từ {@code app.ai.*}).
 *
 * @param baseUrl       ví dụ {@code http://localhost:8000}
 * @param internalToken shared secret cho header {@code X-Internal-Token} (2 chiều BE↔AI)
 */
@ConfigurationProperties(prefix = "app.ai")
public record AiProperties(
        String baseUrl,
        String internalToken
) {
}
