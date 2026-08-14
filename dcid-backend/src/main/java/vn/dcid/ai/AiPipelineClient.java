package vn.dcid.ai;

import vn.dcid.ai.dto.AiIngestRequest;
import vn.dcid.ai.dto.AiQueryRequest;
import vn.dcid.ai.dto.AiQueryResponse;

/** Boundary between the backend and the internal AI service. */
public interface AiPipelineClient {

    /** Queue asynchronous ingestion for an official document version. */
    void ingest(AiIngestRequest request);

    /** Run a synchronous authenticated RAG query. */
    AiQueryResponse query(AiQueryRequest request);

    /** Delete all indexed vectors for an official document. */
    void deleteDocument(java.util.UUID documentId);

    /** Run an authenticated RAG query and forward its SSE payloads. */
    void queryStream(
            AiQueryRequest request,
            java.util.function.Consumer<String> tokenConsumer,
            Runnable onComplete,
            java.util.function.Consumer<Throwable> onError);
}
