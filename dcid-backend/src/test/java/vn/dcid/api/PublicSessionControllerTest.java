package vn.dcid.api;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockMultipartFile;
import vn.dcid.common.ApiResponse;
import vn.dcid.dto.request.QueryRequest;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.dto.response.CreateSessionResponse;
import vn.dcid.dto.response.GuestDocumentDTO;
import vn.dcid.dto.response.GuestSessionDTO;
import vn.dcid.domain.enums.SessionStatus;
import vn.dcid.domain.enums.VersionStatus;
import vn.dcid.service.GuestSessionService;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PublicSessionControllerTest {

    @Mock
    private GuestSessionService sessionService;

    @InjectMocks
    private PublicSessionController publicSessionController;

    private UUID sessionId;
    private String token;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        sessionId = UUID.randomUUID();
        token = "test-token-1234567890";
    }

    @Test
    void createSession_ReturnsCreatedStatus() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRemoteAddr("127.0.0.1");

        CreateSessionResponse sampleResponse = new CreateSessionResponse(sessionId, token, Instant.now().plusSeconds(7200));
        when(sessionService.createSession("127.0.0.1")).thenReturn(sampleResponse);

        ResponseEntity<ApiResponse<CreateSessionResponse>> response = publicSessionController.createSession(request);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(sessionId, response.getBody().data().sessionId());
    }

    @Test
    void getSessionDetail_ReturnsOkStatus() {
        GuestSessionDTO dto = new GuestSessionDTO(sessionId, SessionStatus.ACTIVE, Instant.now(), Instant.now().plusSeconds(7200), 1, 1000L, List.of());
        when(sessionService.getSessionDetail(sessionId, token)).thenReturn(dto);

        ResponseEntity<ApiResponse<GuestSessionDTO>> response = publicSessionController.getSessionDetail(sessionId, token);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(sessionId, response.getBody().data().id());
    }

    @Test
    void uploadDocument_ReturnsCreatedStatus() {
        MockMultipartFile file = new MockMultipartFile("file", "guest.pdf", "application/pdf", "dummy pdf content".getBytes());
        GuestDocumentDTO docDto = new GuestDocumentDTO(UUID.randomUUID(), sessionId, "guest.pdf", 1000L, VersionStatus.PROCESSING, null, null, Instant.now());
        when(sessionService.uploadDocument(eq(sessionId), eq(token), any())).thenReturn(docDto);

        ResponseEntity<ApiResponse<GuestDocumentDTO>> response = publicSessionController.uploadDocument(sessionId, token, file);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("guest.pdf", response.getBody().data().originalFilename());
    }

    @Test
    void askQuestion_ReturnsOkStatus() {
        QueryRequest req = new QueryRequest("Quy định an toàn là gì?", null, false, List.of(), List.of());
        AnswerDTO answer = new AnswerDTO("Theo tài liệu...", 0.95, new AnswerDTO.Guard(false, false, false), List.of());
        when(sessionService.askQuestion(eq(sessionId), eq(token), eq(req))).thenReturn(answer);

        ResponseEntity<ApiResponse<AnswerDTO>> response = publicSessionController.askQuestion(sessionId, token, req);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(0.95, response.getBody().data().confidence());
    }

    @Test
    void deleteSession_ReturnsOkStatus() {
        ResponseEntity<ApiResponse<Void>> response = publicSessionController.deleteSession(sessionId, token);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(sessionService).deleteSession(sessionId, token);
    }
}
