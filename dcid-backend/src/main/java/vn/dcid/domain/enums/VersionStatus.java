package vn.dcid.domain.enums;

/**
 * Vòng đời của một version tài liệu (khớp CHECK trong V2__documents.sql).
 * <pre>
 * PROCESSING → READY → ACTIVE ↔ SUPERSEDED
 *            → FAILED         → OBSOLETE
 * </pre>
 * Retrieval chỉ dùng {@link #ACTIVE}.
 */
public enum VersionStatus {
    PROCESSING,
    READY,
    ACTIVE,
    SUPERSEDED,
    OBSOLETE,
    FAILED
}
