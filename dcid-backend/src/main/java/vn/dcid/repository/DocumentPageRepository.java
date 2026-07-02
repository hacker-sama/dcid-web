package vn.dcid.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.DocumentPage;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DocumentPageRepository extends JpaRepository<DocumentPage, UUID> {

    List<DocumentPage> findByVersionIdOrderByPageNo(UUID versionId);

    Optional<DocumentPage> findByVersionIdAndPageNo(UUID versionId, Integer pageNo);

    /** Xóa pages cũ trước khi ghi lại từ callback (idempotent). */
    void deleteByVersionId(UUID versionId);
}
