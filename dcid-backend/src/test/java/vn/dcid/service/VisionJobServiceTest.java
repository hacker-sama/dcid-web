package vn.dcid.service;

import org.junit.jupiter.api.Test;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.dto.response.VisionJobDTO;
import vn.dcid.exception.NotFoundException;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.Executor;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class VisionJobServiceTest {

    @Test
    void submitRunsOutsideRequestContractAndStoresResultForOwner() {
        QueryService queryService = mock(QueryService.class);
        AnswerDTO answer = new AnswerDTO(
                UUID.randomUUID(),
                "Bản vẽ mô tả cụm camera.",
                0.84,
                new AnswerDTO.Guard(false, false, false),
                List.of());
        when(queryService.askWithVision(
                eq("Phân tích bản vẽ"),
                eq(null),
                eq(false),
                any(byte[].class),
                eq("drawing.png"),
                eq("image/png"),
                any(UUID.class),
                eq(UserRole.ADMIN)))
                .thenReturn(answer);

        Executor directExecutor = Runnable::run;
        VisionJobService service = new VisionJobService(queryService, directExecutor);
        UUID actorId = UUID.randomUUID();

        VisionJobDTO submitted = service.submit(
                "Phân tích bản vẽ",
                null,
                false,
                new byte[]{1, 2, 3},
                "drawing.png",
                "image/png",
                actorId,
                UserRole.ADMIN);

        VisionJobDTO stored = service.get(submitted.jobId(), actorId);
        assertEquals("SUCCEEDED", stored.status());
        assertEquals("DONE", stored.stage());
        assertNotNull(stored.result());
        assertEquals(0.84, stored.result().confidence());
    }

    @Test
    void jobCannotBeReadByAnotherUser() {
        QueryService queryService = mock(QueryService.class);
        when(queryService.askWithVision(
                any(), any(), anyBoolean(), any(byte[].class), any(), any(), any(), any()))
                .thenReturn(AnswerDTO.locked("done"));
        VisionJobService service = new VisionJobService(queryService, Runnable::run);
        UUID owner = UUID.randomUUID();
        VisionJobDTO job = service.submit(
                "question", null, false, new byte[]{1}, "a.png", "image/png",
                owner, UserRole.ADMIN);

        assertThrows(NotFoundException.class, () -> service.get(job.jobId(), UUID.randomUUID()));
    }
}
