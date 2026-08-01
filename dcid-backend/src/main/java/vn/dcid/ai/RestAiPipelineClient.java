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
}


