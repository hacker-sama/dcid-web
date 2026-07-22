package vn.dcid.dto.request;

/**
 * Một tin nhắn trong chuỗi lịch sử hội thoại multi-turn (user/assistant).
 */
public record ChatMessageDTO(
        String role,
        String content
) {
}
