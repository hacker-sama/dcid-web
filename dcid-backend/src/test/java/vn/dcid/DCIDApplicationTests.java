package vn.dcid;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * Full context-load smoke test. Requires the infra stack (Postgres/Redis/Kafka/MinIO).
 * Run it with the stack up, e.g.:
 *   docker-compose up -d && RUN_INTEGRATION_TESTS=true ./mvnw test
 * It is skipped by default so the normal build stays green without infra.
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "RUN_INTEGRATION_TESTS", matches = "true")
class DCIDApplicationTests {

    @Test
    void contextLoads() {
    }
}
