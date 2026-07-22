package vn.dcid.domain.enums;

/**
 * RBAC roles for Smart KCN Docs (see business case §4).
 * <ul>
 *     <li>{@link #OPERATOR}  — công nhân: chỉ tra cứu SOP và cảnh báo an toàn.</li>
 *     <li>{@link #ENGINEER}  — kỹ sư: tra cứu bản vẽ kỹ thuật, sơ đồ mạch, nhật ký bảo trì.</li>
 *     <li>{@link #QA_ADMIN}  — QA/QC &amp; Ban quản lý: upload, đánh dấu obsolete, duyệt version.</li>
 *     <li>{@link #ADMIN}     — quản trị hệ thống: quản lý người dùng, cấu hình, xem audit log.</li>
 * </ul>
 *
 * <p><b>Lưu ý:</b> thứ tự khai báo là thứ bậc quyền tăng dần — {@code ordinal()} được dùng để
 * so sánh phân quyền (QueryService). KHÔNG đổi thứ tự các hằng số.</p>
 */
public enum UserRole {
    OPERATOR,
    ENGINEER,
    QA_ADMIN,
    ADMIN
}
