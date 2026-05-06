package vn.dcid.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import vn.dcid.domain.entity.Notification;
import vn.dcid.domain.enums.NotificationType;
import vn.dcid.dto.response.NotificationDTO;
import vn.dcid.repository.NotificationRepository;

import java.util.List;
import java.util.UUID;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    public void sendNotification(UUID userId, NotificationType type, String title, String message,
                                 UUID relatedApplicationId) {
        // TODO: Implement send notification
        throw new UnsupportedOperationException("TODO: Implement send notification");
    }

    public Page<NotificationDTO> getNotifications(UUID userId, Pageable pageable) {
        // TODO: Implement get notifications
        throw new UnsupportedOperationException("TODO: Implement get notifications");
    }

    public List<NotificationDTO> getUnreadNotifications(UUID userId) {
        // TODO: Implement get unread notifications
        throw new UnsupportedOperationException("TODO: Implement get unread notifications");
    }

    public long getUnreadCount(UUID userId) {
        // TODO: Implement get unread count
        throw new UnsupportedOperationException("TODO: Implement get unread count");
    }

    public void markAsRead(UUID notificationId) {
        // TODO: Implement mark as read
        throw new UnsupportedOperationException("TODO: Implement mark as read");
    }

    public void markAllAsRead(UUID userId) {
        // TODO: Implement mark all as read
        throw new UnsupportedOperationException("TODO: Implement mark all as read");
    }
}
