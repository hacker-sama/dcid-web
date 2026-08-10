package vn.dcid.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.mock.web.MockMultipartFile;
import vn.dcid.ai.AiPipelineClient;
import vn.dcid.common.PageRequest;
import vn.dcid.common.PagedResponse;
import vn.dcid.domain.entity.Document;
import vn.dcid.domain.entity.DocumentVersion;
import vn.dcid.domain.enums.DocumentCategory;
import vn.dcid.domain.enums.UserRole;
import vn.dcid.domain.enums.VersionStatus;
import vn.dcid.dto.request.CreateVersionRequest;
import vn.dcid.dto.response.DocumentDTO;
import vn.dcid.dto.response.DocumentDetailDTO;
import vn.dcid.dto.response.DocumentVersionDTO;
import vn.dcid.exception.ForbiddenException;
import vn.dcid.repository.DocumentPageRepository;
import vn.dcid.repository.DocumentRepository;
import vn.dcid.repository.DocumentVersionRepository;

import java.io.InputStream;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class DocumentServiceTest {

    @Mock
    private DocumentRepository documentRepository;

    @Mock
    private DocumentVersionRepository versionRepository;

    @Mock
    private DocumentPageRepository pageRepository;

    @Mock
    private MinioService minioService;

    @Mock
    private AuditLogService auditLogService;

    @Mock
    private AiPipelineClient aiPipelineClient;

    @InjectMocks
    private DocumentService documentService;

    private UUID docId;
    private UUID v1Id;
    private UUID v2Id;
    private UUID actorId;
    private Document sampleDoc;
    private DocumentVersion sampleV1;
    private DocumentVersion sampleV2;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        docId = UUID.randomUUID();
        v1Id = UUID.randomUUID();
        v2Id = UUID.randomUUID();
        actorId = UUID.randomUUID();

        sampleDoc = new Document();
        sampleDoc.setId(docId);
        sampleDoc.setTitle("Bản vẽ mạch điện CNC");
        sampleDoc.setCategory(DocumentCategory.DRAWING);
        sampleDoc.setMinRole(UserRole.ENGINEER);
        sampleDoc.setCreatedBy(actorId);

        sampleV1 = new DocumentVersion();
        sampleV1.setId(v1Id);
        sampleV1.setDocumentId(docId);
        sampleV1.setVersionNo(1);
        sampleV1.setStorageKey("documents/" + docId + "/v1/original.pdf");
        sampleV1.setStatus(VersionStatus.ACTIVE);

        sampleV2 = new DocumentVersion();
        sampleV2.setId(v2Id);
        sampleV2.setDocumentId(docId);
        sampleV2.setVersionNo(2);
        sampleV2.setStorageKey("documents/" + docId + "/v2/original.pdf");
        sampleV2.setStatus(VersionStatus.PROCESSING);
    }

    @Test
    void createNewVersion_CreatesVersionAndTriggersIngest() {
        when(documentRepository.findById(docId)).thenReturn(Optional.of(sampleDoc));
        when(versionRepository.findMaxVersionNo(docId)).thenReturn(1);
        when(versionRepository.save(any(DocumentVersion.class))).thenAnswer(i -> i.getArgument(0));

        MockMultipartFile file = new MockMultipartFile("file", "v2.pdf", "application/pdf", "dummy pdf content".getBytes());
        CreateVersionRequest req = new CreateVersionRequest();
        req.setFile(file);
        req.setLang("vi");

        DocumentVersionDTO dto = documentService.createNewVersion(docId, req, actorId);

        assertNotNull(dto);
        assertEquals(2, dto.versionNo());
        assertEquals(VersionStatus.PROCESSING, dto.status());
        verify(minioService).upload(eq("documents/" + docId + "/v2/original.pdf"), any(InputStream.class), anyLong(), eq("application/pdf"));
        verify(auditLogService).log(eq(actorId), eq("DOCUMENT_VERSION_CREATE"), eq("DOCUMENT_VERSION"), any(), any(), any());
    }

    @Test
    void publishVersion_SetsTargetActiveAndOldVersionSuperseded() {
        when(versionRepository.findById(v2Id)).thenReturn(Optional.of(sampleV2));
        when(versionRepository.findFirstByDocumentIdAndStatus(docId, VersionStatus.ACTIVE)).thenReturn(Optional.of(sampleV1));
        when(versionRepository.save(any(DocumentVersion.class))).thenAnswer(i -> i.getArgument(0));

        DocumentVersionDTO dto = documentService.publishVersion(docId, v2Id, actorId);

        assertEquals(VersionStatus.ACTIVE, dto.status());
        assertEquals(VersionStatus.SUPERSEDED, sampleV1.getStatus());
        verify(auditLogService).log(eq(actorId), eq("DOCUMENT_VERSION_PUBLISH"), eq("DOCUMENT_VERSION"), eq(v2Id), any(), any());
    }

    @Test
    void obsoleteVersion_SetsStatusToObsolete() {
        when(versionRepository.findById(v1Id)).thenReturn(Optional.of(sampleV1));
        when(versionRepository.save(any(DocumentVersion.class))).thenAnswer(i -> i.getArgument(0));

        DocumentVersionDTO dto = documentService.obsoleteVersion(docId, v1Id, actorId);

        assertEquals(VersionStatus.OBSOLETE, dto.status());
        verify(auditLogService).log(eq(actorId), eq("DOCUMENT_VERSION_OBSOLETE"), eq("DOCUMENT_VERSION"), eq(v1Id), any(), any());
    }

    @Test
    void getDetail_WhenUserHasInsufficientRole_ThrowsForbiddenException() {
        when(documentRepository.findById(docId)).thenReturn(Optional.of(sampleDoc));

        // sampleDoc minRole is ENGINEER (level 2). OPERATOR is level 1.
        assertThrows(ForbiddenException.class, () -> documentService.getDetail(docId, UserRole.OPERATOR));
    }

    @Test
    void getDetail_WhenUserHasSufficientRole_ReturnsDetail() {
        when(documentRepository.findById(docId)).thenReturn(Optional.of(sampleDoc));
        when(versionRepository.findByDocumentIdOrderByVersionNoDesc(docId)).thenReturn(List.of(sampleV1));

        DocumentDetailDTO detail = documentService.getDetail(docId, UserRole.ENGINEER);

        assertNotNull(detail);
        assertEquals("Bản vẽ mạch điện CNC", detail.document().title());
    }

    @Test
    void downloadVersionFile_WhenUserHasInsufficientRole_ThrowsForbiddenException() {
        when(documentRepository.findById(docId)).thenReturn(Optional.of(sampleDoc));

        assertThrows(ForbiddenException.class, () -> documentService.downloadVersionFile(docId, v1Id, UserRole.OPERATOR));
    }
}
