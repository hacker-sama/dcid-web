package vn.dcid.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.DocumentVersion;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.domain.enums.VersionStatus;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DocumentVersionRepository extends JpaRepository<DocumentVersion, UUID> {

    List<DocumentVersion> findByDocumentIdOrderByVersionNoDesc(UUID documentId);

    /** Version đang hiệu lực (unique theo ràng buộc DB). */
    Optional<DocumentVersion> findFirstByDocumentIdAndStatus(UUID documentId, VersionStatus status);

    boolean existsByChecksum(String checksum);

    @Query("SELECT COALESCE(MAX(v.versionNo), 0) FROM DocumentVersion v WHERE v.documentId = :documentId")
    int findMaxVersionNo(@Param("documentId") UUID documentId);

    /**
     * Danh sách version id user được phép truy vấn: status khớp (thường ACTIVE)
     * và min_role của tài liệu nằm trong tập vai được xem. Dùng làm allowedVersionIds cho AI.
     */
    @Query("""
            SELECT v.id FROM DocumentVersion v, Document d
            WHERE d.id = v.documentId AND v.status = :status AND d.minRole IN :minRoles
            """)
    List<UUID> findVersionIdsByStatusAndMinRoles(@Param("status") VersionStatus status,
                                                 @Param("minRoles") Collection<UserRole> minRoles);

    /** Như trên, lọc thêm theo mã máy. */
    @Query("""
            SELECT v.id FROM DocumentVersion v, Document d
            WHERE d.id = v.documentId AND v.status = :status AND d.minRole IN :minRoles
              AND d.machineCode = :machineCode
            """)
    List<UUID> findVersionIdsByStatusAndMinRolesAndMachineCode(@Param("status") VersionStatus status,
                                                               @Param("minRoles") Collection<UserRole> minRoles,
                                                               @Param("machineCode") String machineCode);
}
