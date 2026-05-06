package vn.dcid.api.citizen;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.dto.response.NotificationDTO;

import java.util.List;

@RestController
@RequestMapping("/api/citizens/notifications")
public class CitizenNotificationController {

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<NotificationDTO>>> getNotifications(Pageable pageable) {
        throw new UnsupportedOperationException("TODO: Implement get notifications");
    }

    @GetMapping("/unread")
    public ResponseEntity<ApiResponse<List<NotificationDTO>>> getUnreadNotifications() {
        throw new UnsupportedOperationException("TODO: Implement get unread notifications");
    }

    @GetMapping("/unread/count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount() {
        throw new UnsupportedOperationException("TODO: Implement get unread count");
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(@PathVariable java.util.UUID id) {
        throw new UnsupportedOperationException("TODO: Implement mark as read");
    }

    @PostMapping("/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead() {
        throw new UnsupportedOperationException("TODO: Implement mark all as read");
    }
}
