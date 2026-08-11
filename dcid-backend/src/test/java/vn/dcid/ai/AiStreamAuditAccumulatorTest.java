package vn.dcid.ai;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class AiStreamAuditAccumulatorTest {

    @Test
    void collectsMetadataAndAnswerPreview() {
        UUID versionId = UUID.randomUUID();
        AiStreamAuditAccumulator audit = new AiStreamAuditAccumulator();

        audit.accept("{\"event\":\"meta\",\"confidence\":0.82,"
                + "\"guard\":{\"locked\":false,\"numericRule\":true},"
                + "\"citations\":[{\"versionId\":\"" + versionId + "\"}]}");
        audit.accept("{\"event\":\"delta\",\"text\":\"Dien ap \"}");
        audit.accept("{\"event\":\"delta\",\"text\":\"220 VAC\"}");

        assertEquals(versionId, audit.matchedVersionId());
        assertNotNull(audit.confidence());
        assertEquals(0.82, audit.confidence().doubleValue(), 0.0001);
        assertTrue(audit.numericRule());
        assertFalse(audit.locked());
        assertEquals("Dien ap 220 VAC", audit.answerPreview());
    }

    @Test
    void aiErrorOverridesUnlockedMeta() {
        AiStreamAuditAccumulator audit = new AiStreamAuditAccumulator();

        audit.accept("{\"event\":\"meta\",\"confidence\":0.75,"
                + "\"guard\":{\"locked\":false,\"numericRule\":false},\"citations\":[]}");
        audit.accept("{\"event\":\"error\",\"message\":\"Ollama timeout\"}");

        assertTrue(audit.locked());
        assertEquals("Ollama timeout", audit.answerPreview());
    }

    @Test
    void transportErrorIsLockedAndPreviewIsBounded() {
        AiStreamAuditAccumulator audit = new AiStreamAuditAccumulator();
        audit.accept("{\"event\":\"delta\",\"text\":\"" + "x".repeat(800) + "\"}");
        audit.markTransportError(new RuntimeException("connection closed"));

        assertTrue(audit.locked());
        assertEquals(500, audit.answerPreview().length());
    }

    @Test
    void malformedStreamFailsClosed() {
        AiStreamAuditAccumulator audit = new AiStreamAuditAccumulator();

        audit.accept("not-json");

        assertTrue(audit.locked());
        assertNull(audit.confidence());
    }
}
