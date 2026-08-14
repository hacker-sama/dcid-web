package vn.dcid.dto.request;

import jakarta.validation.constraints.NotNull;
import org.springframework.web.multipart.MultipartFile;

/**
 * Multipart form để upload một phiên bản mới (v2, v3...) của tài liệu đã tồn tại.
 */
public class CreateVersionRequest {

    @NotNull(message = "file is required")
    private MultipartFile file;

    /** Ngôn ngữ nội dung, ví dụ "vi", "en", "vi,en". */
    private String lang;

    private String changelog;

    public MultipartFile getFile() {
        return file;
    }

    public void setFile(MultipartFile file) {
        this.file = file;
    }

    public String getLang() {
        return lang;
    }

    public void setLang(String lang) {
        this.lang = lang;
    }

    public String getChangelog() {
        return changelog;
    }

    public void setChangelog(String changelog) {
        this.changelog = changelog;
    }
}
