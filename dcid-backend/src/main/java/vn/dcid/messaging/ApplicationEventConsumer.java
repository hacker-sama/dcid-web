package vn.dcid.messaging;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;
import vn.dcid.messaging.event.ApplicationEvent;

@Component
public class ApplicationEventConsumer {

    private static final Logger log = LoggerFactory.getLogger(ApplicationEventConsumer.class);

    @KafkaListener(
            topics = "${app.kafka.topics.application-events:application-events}",
            groupId = "${spring.kafka.consumer.group-id}",
            containerFactory = "kafkaListenerContainerFactory"
    )
    public void handleApplicationEvent(
            @Payload ApplicationEvent event,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            Acknowledgment acknowledgment,
            ConsumerRecord<String, Object> record) {

        try {
            log.info("Received application event: type={}, applicationId={}, status={}",
                    event.eventType(), event.applicationId(), event.status());

            switch (event.eventType()) {
                case "APPLICATION_SUBMITTED" -> handleApplicationSubmitted(event);
                case "STATUS_CHANGED" -> handleStatusChanged(event);
                case "APPLICATION_APPROVED" -> handleApplicationApproved(event);
                case "APPLICATION_REJECTED" -> handleApplicationRejected(event);
                default -> log.warn("Unknown event type: {}", event.eventType());
            }

            if (acknowledgment != null) {
                acknowledgment.acknowledge();
            }
        } catch (Exception e) {
            log.error("Error processing application event", e);
            throw new UnsupportedOperationException("TODO: Implement DLQ handling", e);
        }
    }

    private void handleApplicationSubmitted(ApplicationEvent event) {
        throw new UnsupportedOperationException("TODO: Implement handle application submitted");
    }

    private void handleStatusChanged(ApplicationEvent event) {
        throw new UnsupportedOperationException("TODO: Implement handle status changed");
    }

    private void handleApplicationApproved(ApplicationEvent event) {
        throw new UnsupportedOperationException("TODO: Implement handle application approved");
    }

    private void handleApplicationRejected(ApplicationEvent event) {
        throw new UnsupportedOperationException("TODO: Implement handle application rejected");
    }
}
