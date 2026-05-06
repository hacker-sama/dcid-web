package vn.dcid.api.officer;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.common.ApiResponse;

import java.util.Map;

@RestController
@RequestMapping("/api/officers/dashboard")
public class OfficerDashboardController {

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDashboardStats() {
        throw new UnsupportedOperationException("TODO: Implement get dashboard stats");
    }

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPendingApplications() {
        throw new UnsupportedOperationException("TODO: Implement get pending applications");
    }

    @GetMapping("/recent")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getRecentActivity() {
        throw new UnsupportedOperationException("TODO: Implement get recent activity");
    }
}
