package vn.dcid.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Pure WebSocket for Flutter Web / Mobile / native STOMP clients
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");

        // SockJS fallback on separate endpoint
        registry.addEndpoint("/ws-sockjs")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }
}
