package vn.dcid.api;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import vn.dcid.common.ApiResponse;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.QueryLog;
import vn.dcid.domain.entity.User;
import vn.dcid.dto.request.FeedbackRequest;
import vn.dcid.dto.response.QueryHistoryDTO;
import vn.dcid.exception.NotFoundException;
import vn.dcid.repository.QueryLogRepository;
import vn.dcid.service.UserService;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class QueryHistoryAndFeedbackTest {

    @Mock
    private QueryLogRepository queryLogRepository;

    @Mock
    private UserService userService;

    @InjectMocks
    private QueryHistoryController historyController;

    @InjectMocks
    private FeedbackController feedbackController;

    private User sampleUser;
    private UUID sampleUserId;
    private QueryLog sampleLog;
    private UUID sampleLogId;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);

        sampleUserId = UUID.randomUUID();
        sampleUser = new User();
        sampleUser.setId(sampleUserId);
        sampleUser.setUsername("testuser");

        sampleLogId = UUID.randomUUID();
        sampleLog = new QueryLog();
        sampleLog.setId(sampleLogId);
        sampleLog.setActorId(sampleUserId);
        sampleLog.setQuestion("Cách vận hành máy CNC?");
        sampleLog.setAnswerPreview("Bước 1 bật máy...");
        sampleLog.setConfidence(new BigDecimal("0.950"));
        sampleLog.setLocked(false);
        sampleLog.setNumericRuleHit(false);
        sampleLog.setLatencyMs(350);
        sampleLog.setCreatedAt(Instant.now());
    }

    @Test
    void getHistory_Success() {
        when(userService.getCurrentUser()).thenReturn(sampleUser);
        when(queryLogRepository.findByActorIdOrderByCreatedAtDesc(eq(sampleUserId), any(PageRequest.class)))
                .thenReturn(new PageImpl<>(List.of(sampleLog)));

        ResponseEntity<ApiResponse<PagedResponse<QueryHistoryDTO>>> response =
                historyController.getHistory(0, 20);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().data().total());
        assertEquals("Cách vận hành máy CNC?", response.getBody().data().items().get(0).question());
    }

    @Test
    void submitFeedback_Helpful_Success() {
        when(userService.getCurrentUser()).thenReturn(sampleUser);
        when(queryLogRepository.findByIdAndActorId(sampleLogId, sampleUserId))
                .thenReturn(Optional.of(sampleLog));

        FeedbackRequest req = new FeedbackRequest(true, "Rất hữu ích");
        ResponseEntity<ApiResponse<Void>> response = feedbackController.submitFeedback(sampleLogId, req);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals((short) 1, sampleLog.getFeedback());
        assertEquals("Rất hữu ích", sampleLog.getFeedbackNote());
        assertNotNull(sampleLog.getFeedbackAt());
        verify(queryLogRepository).save(sampleLog);
    }

    @Test
    void submitFeedback_NotHelpful_Success() {
        when(userService.getCurrentUser()).thenReturn(sampleUser);
        when(queryLogRepository.findByIdAndActorId(sampleLogId, sampleUserId))
                .thenReturn(Optional.of(sampleLog));

        FeedbackRequest req = new FeedbackRequest(false, "Sai số liệu");
        ResponseEntity<ApiResponse<Void>> response = feedbackController.submitFeedback(sampleLogId, req);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals((short) -1, sampleLog.getFeedback());
        assertEquals("Sai số liệu", sampleLog.getFeedbackNote());
        assertNotNull(sampleLog.getFeedbackAt());
        verify(queryLogRepository).save(sampleLog);
    }

    @Mock
    private vn.dcid.repository.UserRepository userRepository;

    @InjectMocks
    private FeedbackAdminController feedbackAdminController;

    @Test
    void getFeedbacks_Admin_Success() {
        sampleLog.setFeedback((short) 1);
        sampleLog.setFeedbackNote("Rất tốt");
        sampleLog.setFeedbackAt(Instant.now());

        when(queryLogRepository.findFeedbacks(eq((short) 1), any(PageRequest.class)))
                .thenReturn(new PageImpl<>(List.of(sampleLog)));
        when(userRepository.findAllById(List.of(sampleUserId)))
                .thenReturn(List.of(sampleUser));

        var response = feedbackAdminController.getFeedbacks((short) 1, 0, 20);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().data().total());
        assertEquals("testuser", response.getBody().data().items().get(0).actorUsername());
        assertEquals((short) 1, response.getBody().data().items().get(0).feedback());
        assertEquals("Rất tốt", response.getBody().data().items().get(0).feedbackNote());
    }

    @Test
    void clearHistory_Success() {
        when(userService.getCurrentUser()).thenReturn(sampleUser);

        ResponseEntity<ApiResponse<String>> response = historyController.clearHistory();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(queryLogRepository).deleteByActorId(sampleUserId);
    }

    @Test
    void deleteHistoryById_Success() {
        when(userService.getCurrentUser()).thenReturn(sampleUser);

        ResponseEntity<ApiResponse<String>> response = historyController.deleteHistoryById(sampleLogId);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(queryLogRepository).deleteByIdAndActorId(sampleLogId, sampleUserId);
    }

    @Mock
    private vn.dcid.service.AnalyticsService analyticsService;

    @InjectMocks
    private AnalyticsController analyticsController;

    @Test
    void resetAnalytics_Success() {
        when(userService.getCurrentUser()).thenReturn(sampleUser);
        org.springframework.mock.web.MockHttpServletRequest request = new org.springframework.mock.web.MockHttpServletRequest();
        request.setRemoteAddr("127.0.0.1");

        ResponseEntity<ApiResponse<String>> response = analyticsController.resetAnalytics(request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(analyticsService).resetSystemAnalytics(eq(sampleUserId), eq("127.0.0.1"));
    }
}
