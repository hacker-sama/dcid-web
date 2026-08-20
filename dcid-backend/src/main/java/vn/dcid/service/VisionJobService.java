package vn.dcid.service;

import org.springframework.beans.factory.annotation.Qualifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.dto.response.AnswerDTO;
import vn.dcid.dto.response.VisionJobDTO;
import vn.dcid.exception.NotFoundException;
import vn.dcid.exception.ServiceUnavailableException;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executor;
import java.util.concurrent.RejectedExecutionException;

/**
 * Runs synchronous OCR/Vision work outside the browser request lifecycle.
 * Jobs are intentionally in-memory because the deployment currently has one
 * backend replica; completed snapshots expire automatically after 30 minutes.
 */
@Service
public class VisionJobService {

    private static final Logger log = LoggerFactory.getLogger(VisionJobService.class);
    private static final Duration JOB_TTL = Duration.ofMinutes(30);
    private static final long SSE_TIMEOUT_MS = Duration.ofMinutes(15).toMillis();

    private final QueryService queryService;
    private final Executor executor;
    private final ConcurrentHashMap<UUID, JobState> jobs = new ConcurrentHashMap<>();

    public VisionJobService(QueryService queryService,
                            @Qualifier("visionJobExecutor") Executor executor) {
        this.queryService = queryService;
        this.executor = executor;
    }

    public VisionJobDTO submit(String question, String machineCode, boolean reasoningMode,
                               byte[] fileBytes, String filename, String contentType,
                               UUID actorId, UserRole actorRole) {
        UUID jobId = UUID.randomUUID();
        JobState state = new JobState(jobId, actorId);
        jobs.put(jobId, state);

        try {
            executor.execute(() -> runJob(
                    state,
                    question,
                    machineCode,
                    reasoningMode,
                    fileBytes,
                    filename,
                    contentType,
                    actorId,
                    actorRole));
        } catch (RejectedExecutionException ex) {
            jobs.remove(jobId);
            throw new ServiceUnavailableException(
                    "Hàng đợi phân tích ảnh đã đầy; vui lòng thử lại sau", ex);
        }
        return state.snapshot();
    }

    public VisionJobDTO get(UUID jobId, UUID actorId) {
        return ownedState(jobId, actorId).snapshot();
    }

    public SseEmitter events(UUID jobId, UUID actorId) {
        JobState state = ownedState(jobId, actorId);
        SseEmitter emitter = new SseEmitter(SSE_TIMEOUT_MS);
        state.emitters.add(emitter);
        emitter.onCompletion(() -> state.emitters.remove(emitter));
        emitter.onTimeout(() -> state.emitters.remove(emitter));
        emitter.onError(_error -> state.emitters.remove(emitter));
        send(emitter, state.snapshot());
        return emitter;
    }

    private void runJob(JobState state, String question, String machineCode, boolean reasoningMode,
                        byte[] fileBytes, String filename, String contentType,
                        UUID actorId, UserRole actorRole) {
        state.status = "PROCESSING";
        state.stage = "OCR_AND_VISION";
        state.updatedAt = Instant.now();
        publish(state);
        try {
            AnswerDTO answer = queryService.askWithVision(
                    question,
                    machineCode,
                    reasoningMode,
                    fileBytes,
                    filename,
                    contentType,
                    actorId,
                    actorRole);
            state.result = answer;
            state.status = "SUCCEEDED";
            state.stage = "DONE";
        } catch (Exception ex) {
            log.error("Vision job failed jobId={} actorId={}", state.jobId, actorId, ex);
            state.error = "Không thể hoàn tất phân tích ảnh";
            state.status = "FAILED";
            state.stage = "FAILED";
        } finally {
            state.updatedAt = Instant.now();
            publish(state);
            completeEmitters(state);
        }
    }

    private JobState ownedState(UUID jobId, UUID actorId) {
        JobState state = jobs.get(jobId);
        if (state == null || !state.actorId.equals(actorId)) {
            throw new NotFoundException("Không tìm thấy job phân tích ảnh");
        }
        return state;
    }

    private void publish(JobState state) {
        VisionJobDTO snapshot = state.snapshot();
        for (SseEmitter emitter : List.copyOf(state.emitters)) {
            send(emitter, snapshot);
        }
    }

    private void send(SseEmitter emitter, VisionJobDTO snapshot) {
        try {
            emitter.send(SseEmitter.event().name("vision-job").data(snapshot));
        } catch (IOException | IllegalStateException ex) {
            emitter.complete();
        }
    }

    private void completeEmitters(JobState state) {
        for (SseEmitter emitter : List.copyOf(state.emitters)) {
            emitter.complete();
        }
        state.emitters.clear();
    }

    @Scheduled(fixedRate = 15_000)
    void heartbeat() {
        for (JobState state : jobs.values()) {
            if (!"SUCCEEDED".equals(state.status) && !"FAILED".equals(state.status)) {
                publish(state);
            }
        }
    }

    @Scheduled(fixedDelay = 300_000)
    void removeExpiredJobs() {
        Instant cutoff = Instant.now().minus(JOB_TTL);
        jobs.entrySet().removeIf(entry -> entry.getValue().updatedAt.isBefore(cutoff));
    }

    private static final class JobState {
        private final UUID jobId;
        private final UUID actorId;
        private final CopyOnWriteArrayList<SseEmitter> emitters = new CopyOnWriteArrayList<>();
        private volatile String status = "QUEUED";
        private volatile String stage = "QUEUED";
        private volatile AnswerDTO result;
        private volatile String error;
        private volatile Instant updatedAt = Instant.now();

        private JobState(UUID jobId, UUID actorId) {
            this.jobId = jobId;
            this.actorId = actorId;
        }

        private VisionJobDTO snapshot() {
            return new VisionJobDTO(jobId, status, stage, result, error);
        }
    }
}
