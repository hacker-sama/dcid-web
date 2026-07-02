package vn.dcid.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.dcid.domain.entity.Document;
import vn.dcid.domain.enums.DocumentCategory;

import java.util.UUID;

@Repository
public interface DocumentRepository extends JpaRepository<Document, UUID> {

    Page<Document> findByMachineCode(String machineCode, Pageable pageable);

    Page<Document> findByCategory(DocumentCategory category, Pageable pageable);
}
