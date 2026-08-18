package vn.dcid.domain.enums;

/**
 * RBAC roles for DCID (see business case §4).
 * <ul>
 *     <li>{@link #OPERATOR}  — công nhân: chỉ tra cứu SOP và cảnh báo an toàn.</li>
 *     <li>{@link #ENGINEER}  — kỹ sư: tra cứu bản vẽ kỹ thuật, sơ đồ mạch, nhật ký bảo trì.</li>
 *     <li>{@link #QA_ADMIN}  — QA/QC &amp; Ban quản lý: upload, đánh dấu obsolete, duyệt version.</li>
 *     <li>{@link #ADMIN}     — quản trị hệ thống: quản lý người dùng, cấu hình, xem audit log.</li>
 * </ul>
 *
 * <p><b>Lưu ý:</b> Sử dụng {@link #getLevel()} thay vì {@code ordinal()} để so sánh phân quyền.
 * {@code ordinal()} phụ thuộc vào thứ tự khai báo và dễ bị vỡ RBAC khi thêm Enum mới.
 * {@code level} là giá trị số nguyên CỐ ĐỊNH không thay đổi.</p>
 */
public enum UserRole {
    OPERATOR(1),
    ENGINEER(2),
    QA_ADMIN(3),
    ADMIN(4);

    private final int level;

    UserRole(int level) {
        this.level = level;
    }

    /**
     * Trả về mức độ phân quyền cố định (1=thấp nhất, 4=cao nhất).
     * Dùng thay thế {@code ordinal()} để đảm bảo RBAC không bị vỡ khi mở rộng Enum.
     */
    public int getLevel() {
        return level;
    }
}
