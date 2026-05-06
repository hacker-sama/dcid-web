package vn.dcid.messaging;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;
import vn.dcid.messaging.event.ApplicationEvent;

import java.time.Instant;
import java.util.UUID;

@Component
public class ApplicationEventProducer {

    private static final Logger log = LoggerFactory.getLogger(ApplicationEventProducer.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;

    @Value("${app.kafka.topics.application-events:application-events}")
    private String applicationEventsTopic;

    public ApplicationEventProducer(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void publishEvent(String eventType, UUID applicationId, UUID applicantId, String status) {
        // TODO: Implement event publishing
        ApplicationEvent event = new ApplicationEvent(
                eventType,
                applicationId,
                applicantId,
                status,
                Instant.now()
        );

        try {
            kafkaTemplate.send(applicationEventsTopic, applicationId.toString(), event);
            log.info("Published application event: type={}, applicationId={}, status={}",
                    eventType, applicationId, status);
        } catch (Exception e) {
            log.error("Failed to publish application event: type={}, applicationId={}",
                    eventType, applicationId, e);
            throw new UnsupportedOperationException("TODO: Implement event publish error handling", e);
        }
    }
}
