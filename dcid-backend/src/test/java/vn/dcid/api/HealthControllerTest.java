package vn.dcid.api;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Plain unit test — no Spring context, so it stays green without the infra stack.
 */
class HealthControllerTest {

    @Test
    void healthEndpointShouldReturnUp() {
        ResponseEntity<Map<String, String>> response = new HealthController().health();

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody())
                .containsEntry("status", "UP")
                .containsEntry("service", "dcid-backend");
    }
}
