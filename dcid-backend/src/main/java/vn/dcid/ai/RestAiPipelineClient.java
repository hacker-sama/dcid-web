package vn.dcid.ai;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import vn.dcid.ai.dto.AiIngestRequest;
import vn.dcid.ai.dto.AiQueryRequest;
import vn.dcid.ai.dto.AiQueryResponse;
import vn.dcid.exception.ServiceUnavailableException;
import java.util.UUID;

@Component

public class RestAiPipelineClient implements AiPipelineClient {

    private final RestClient restClient;

    public RestAiPipelineClient(RestClient aiRestClient) {
        this.restClient = aiRestClient;
    }

    @Override
    public void ingest(AiIngestRequest request) {
        try {
            restClient.post()
                    .uri("/ai/ingest")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientException e) {
            throw new ServiceUnavailableException("AI service không phản hồi khi ingest", e);
        }
    }

    @Override
    public AiQueryResponse query(AiQueryRequest request) {
        try {
            AiQueryResponse response = restClient.post()
                    .uri("/ai/query")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(AiQueryResponse.class);
            if (response == null) {
                throw new ServiceUnavailableException("AI service trả về rỗng khi query");
            }
            return response;
        } catch (RestClientException e) {
            throw new ServiceUnavailableException("AI service không phản hồi khi query", e);
        }
    }

    @Override
    public void deleteDocument(UUID documentId) {
        try {
            restClient.delete()
                    .uri("/ai/documents/{documentId}", documentId)
                    .retrieve()
                    .toBodilessEntity();
        } catch (Exception e) {
            // Log warning nhưng không throw exception để tránh block luồng xóa DB
            org.slf4j.LoggerFactory.getLogger(RestAiPipelineClient.class)
                    .warn("Lỗi khi thông báo AI service xóa vector documentId={}: {}", documentId, e.getMessage());
        }
    }

    @Override
    public void deleteGuestSessionVectors(UUID sessionId) {
        try {
            restClient.delete()
                    .uri("/ai/guest/sessions/{sessionId}", sessionId)
                    .retrieve()
                    .toBodilessEntity();
        } catch (Exception e) {
            org.slf4j.LoggerFactory.getLogger(RestAiPipelineClient.class)
                    .warn("Lỗi khi thông báo AI service xóa vector guest sessionId={}: {}", sessionId, e.getMessage());
        }
    }

    @Override
    public void queryStream(AiQueryRequest request, java.util.function.Consumer<String> tokenConsumer, Runnable onComplete, java.util.function.Consumer<Throwable> onError) {
        try {
            restClient.post()
                    .uri("/ai/query/stream")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .accept(MediaType.TEXT_EVENT_STREAM)
                    .exchange((req, res) -> {
                        try (java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(res.getBody()))) {
                            String line;
                            while ((line = reader.readLine()) != null) {
                                if (line.startsWith("data:")) {
                                    tokenConsumer.accept(line.substring(5).trim());
                                }
                            }
                            onComplete.run();
                        } catch (Exception ex) {
                            onError.accept(ex);
                        }
                        return null;
                    });
        } catch (Exception e) {
            onError.accept(e);
        }
    }
}


