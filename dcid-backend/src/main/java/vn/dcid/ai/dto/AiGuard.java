package vn.dcid.ai.dto;

/** Kết quả guardrail từ AI: locked (cosine < θ) / numericRule (trích số liệu bằng rule). */
public record AiGuard(
        boolean locked,
        boolean numericRule
) {
}
