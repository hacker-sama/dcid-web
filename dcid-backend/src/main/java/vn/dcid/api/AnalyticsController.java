package vn.dcid.api;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.common.ApiResponse;
import vn.dcid.domain.entity.User;
import vn.dcid.dto.response.AnalyticsDTO;
import vn.dcid.service.AnalyticsService;
import vn.dcid.service.UserService;

@RestController
@RequestMapping("/api/admin/analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;
    private final UserService userService;

    public AnalyticsController(AnalyticsService analyticsService, UserService userService) {
        this.analyticsService = analyticsService;
        this.userService = userService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'QA_ADMIN')")
    public ResponseEntity<ApiResponse<AnalyticsDTO>> getAnalytics() {
        AnalyticsDTO analytics = analyticsService.getSystemAnalytics();
        return ResponseEntity.ok(ApiResponse.of(analytics));
    }

    @DeleteMapping("/reset")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> resetAnalytics(HttpServletRequest request) {
        User admin = userService.getCurrentUser();
        String clientIp = request.getRemoteAddr();
        analyticsService.resetSystemAnalytics(admin.getId(), clientIp);
        return ResponseEntity.ok(ApiResponse.of("System analytics and query logs have been reset successfully."));
    }
}
