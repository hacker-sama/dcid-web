package vn.dcid.api;

import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.util.StreamUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.dcid.domain.entity.DocumentPage;
import vn.dcid.exception.NotFoundException;
import vn.dcid.repository.DocumentPageRepository;
import vn.dcid.service.MinioService;

import java.io.InputStream;
import java.util.UUID;

@RestController
@RequestMapping("/api/files")
public class FileProxyController {

    private final DocumentPageRepository pageRepository;
    private final MinioService minioService;

    public FileProxyController(DocumentPageRepository pageRepository, MinioService minioService) {
        this.pageRepository = pageRepository;
        this.minioService = minioService;
    }

    @GetMapping("/{versionId}/{pageNo}/{bboxKey}")
    public void getFile(
            @PathVariable UUID versionId,
            @PathVariable int pageNo,
            @PathVariable String bboxKey,
            HttpServletResponse response) {

        DocumentPage page = pageRepository.findByVersionIdAndPageNo(versionId, pageNo)
                .orElseThrow(() -> new NotFoundException("DocumentPage", versionId + "-" + pageNo));

        String imageKey = page.getImageKey();
        if (imageKey == null || imageKey.isBlank()) {
            throw new NotFoundException("ImageKey", versionId + "-" + pageNo);
        }

        response.setContentType("image/png");
        response.setHeader(HttpHeaders.CACHE_CONTROL, "max-age=3600");

        try (InputStream is = minioService.download(imageKey)) {
            StreamUtils.copy(is, response.getOutputStream());
        } catch (Exception e) {
            throw new IllegalStateException("Lỗi tải file", e);
        }
    }
}
