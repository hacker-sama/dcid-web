package vn.dcid.websocket;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;
import vn.dcid.messaging.event.ApplicationEvent;

import java.time.Instant;
import java.util.UUID;

@Controller
public class ApplicationStatusWebSocketHandler {

    @MessageMapping("/app/application-status")
    @SendTo("/topic/application-status")
    public ApplicationEvent handleStatusUpdate(ApplicationEvent event) {
        throw new UnsupportedOperationException("TODO: Implement WebSocket status update handler");
    }

    @MessageMapping("/app/subscribe-application")
    @SendTo("/topic/application-updates")
    public ApplicationEvent handleSubscription(UUID applicationId) {
        throw new UnsupportedOperationException("TODO: Implement WebSocket subscription handler");
    }
}
