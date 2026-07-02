package vn.dcid.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.web.multipart.MultipartFile;
import vn.dcid.domain.enums.DocumentCategory;
import vn.dcid.domain.enums.UserRole;

/**
 * Multipart form để tạo tài liệu + upload version đầu tiên.
 * Bind qua {@code @ModelAttribute}: các trường text + phần file "file".
 */
public class CreateDocumentRequest {

    @NotBlank(message = "title is required")
    private String title;

    private String machineCode;

    @NotNull(message = "category is required")
    private DocumentCategory category;

    /** Vai tối thiểu được xem; mặc định OPERATOR nếu bỏ trống. */
    private UserRole minRole;

    private String description;

    /** Ngôn ngữ nội dung, ví dụ "vi", "en", "vi,en". */
    private String lang;

    @NotNull(message = "file is required")
    private MultipartFile file;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMachineCode() {
        return machineCode;
    }

    public void setMachineCode(String machineCode) {
        this.machineCode = machineCode;
    }

    public DocumentCategory getCategory() {
        return category;
    }

    public void setCategory(DocumentCategory category) {
        this.category = category;
    }

    public UserRole getMinRole() {
        return minRole;
    }

    public void setMinRole(UserRole minRole) {
        this.minRole = minRole;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getLang() {
        return lang;
    }

    public void setLang(String lang) {
        this.lang = lang;
    }

    public MultipartFile getFile() {
        return file;
    }

    public void setFile(MultipartFile file) {
        this.file = file;
    }
}
