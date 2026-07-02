package vn.dcid.ai;

import vn.dcid.ai.dto.AiIngestRequest;
import vn.dcid.ai.dto.AiQueryRequest;
import vn.dcid.ai.dto.AiQueryResponse;

/**
 * Ranh giới BE → AI service (dcid-ai). Hợp đồng: docs/API-CONTRACT.md.
 * Interface tách riêng để test bằng mock khi AI chưa chạy.
 */
public interface AiPipelineClient {

    /** Kích hoạt ingest bất đồng bộ; AI trả 202 rồi báo kết quả qua /api/internal/ingest-callback. */
    void ingest(AiIngestRequest request);

    /** Truy vấn RAG đồng bộ. */
    AiQueryResponse query(AiQueryRequest request);
}
