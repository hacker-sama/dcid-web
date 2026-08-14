package vn.dcid.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.UUID;

/**
 * Collects the small amount of metadata needed to audit an AI SSE response.
 * It intentionally stores only the first 500 answer characters so streaming
 * does not introduce an unbounded in-memory buffer.
 */
public final class AiStreamAuditAccumulator {

    private static final int MAX_PREVIEW_LENGTH = 500;
    private static final ObjectMapper JSON = new ObjectMapper();

    private final StringBuilder answerPreview = new StringBuilder(MAX_PREVIEW_LENGTH);
    private UUID matchedVersionId;
    private double confidence;
    private boolean hasConfidence;
    private boolean numericRule;
    // Fail closed until a valid meta event explicitly reports the guard state.
    private boolean locked = true;

    public void accept(String payload) {
        try {
            JsonNode root = JSON.readTree(payload);
            String event = root.path("event").asText("");
            switch (event) {
                case "meta" -> readMeta(root);
                case "delta" -> appendPreview(root.path("text").asText(""));
                case "error" -> {
                    locked = true;
                    if (answerPreview.isEmpty()) {
                        appendPreview(root.path("message").asText("AI stream failed"));
                    }
                }
                default -> {
                    // done and future event types carry no audit fields.
                }
            }
        } catch (Exception ignored) {
            // Forward-compatible: malformed/unknown payloads still reach the
            // client, but they cannot corrupt the audit state.
        }
    }

    public void markTransportError(Throwable error) {
        locked = true;
        if (answerPreview.isEmpty()) {
            appendPreview(error != null && error.getMessage() != null
                    ? error.getMessage()
                    : "AI stream connection failed");
        }
    }

    private void readMeta(JsonNode root) {
        JsonNode confidenceNode = root.get("confidence");
        if (confidenceNode != null && confidenceNode.isNumber()) {
            confidence = Math.max(0.0, Math.min(1.0, confidenceNode.asDouble()));
            hasConfidence = true;
        }

        JsonNode guard = root.path("guard");
        locked = guard.path("locked").asBoolean(false);
        numericRule = guard.path("numericRule").asBoolean(false);

        JsonNode citations = root.path("citations");
        if (citations.isArray() && !citations.isEmpty()) {
            String versionId = citations.get(0).path("versionId").asText("");
            try {
                matchedVersionId = UUID.fromString(versionId);
            } catch (IllegalArgumentException ignored) {
                matchedVersionId = null;
            }
        }
    }

    private void appendPreview(String text) {
        int remaining = MAX_PREVIEW_LENGTH - answerPreview.length();
        if (remaining > 0 && text != null) {
            answerPreview.append(text, 0, Math.min(remaining, text.length()));
        }
    }

    public UUID matchedVersionId() {
        return matchedVersionId;
    }

    public Double confidence() {
        return hasConfidence ? confidence : null;
    }

    public boolean numericRule() {
        return numericRule;
    }

    public boolean locked() {
        return locked;
    }

    public String answerPreview() {
        return answerPreview.isEmpty() ? "[Streaming Response]" : answerPreview.toString();
    }
}
