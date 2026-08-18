package vn.dcid.api;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.common.ApiResponse;
import vn.dcid.dto.response.AnalyticsDTO;
import vn.dcid.service.AnalyticsService;

@RestController
@RequestMapping("/api/admin/analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'QA_ADMIN')")
    public ResponseEntity<ApiResponse<AnalyticsDTO>> getAnalytics() {
        AnalyticsDTO analytics = analyticsService.getSystemAnalytics();
        return ResponseEntity.ok(ApiResponse.of(analytics));
    }
}
