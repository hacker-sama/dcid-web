import 'app_locale.dart';

abstract class AppStrings {
  // App & Branding
  String get appTitle;
  String get appSubtitle;
  String get appFullName;
  String get appTagline;

  // Auth / Login
  String get loginHeadline;
  String get username;
  String get password;
  String get signIn;
  String get authFailed;
  String get usernameRequired;
  String get passwordRequired;

  // Shell / Navigation
  String get navDocuMind;
  String get navSnapAsk;
  String get navDocuments;
  String get navAdmin;
  String get newChat;
  String get recents;
  String get profileTooltip;
  String get profileMenuTooltip;
  String get historyTooltip;
  String get logoutTooltip;
  String get expandSidebar;
  String get collapseSidebar;
  String get switchToLight;
  String get switchToDark;
  String get switchLanguage;
  String get currentLanguage;

  // Roles
  String get roleOperator;
  String get roleEngineer;
  String get roleQaAdmin;
  String get roleAdmin;

  // Search / DocuMind
  String get searchHeroTitle;
  String get searchHeroSubtitle;
  String get searchPlaceholderAll;
  String searchPlaceholderSelected(int count);
  String get insufficientConfidenceBanner;
  String get lockedAnswerWarning;
  String get directDataExtraction;
  String get reasoningMode;
  String get referenceSources;
  String get copy;
  String get copied;
  String get copyAnswerSuccess;
  String get copySuccessSnackbar;
  String get wasAnswerHelpful;
  String get feedbackThanks;
  String get thankYouFeedback;
  String get helpful;
  String get notHelpful;
  String get citations;
  String get confidence;
  String get aiDisclaimer;
  String get allDocsScope;
  String get clearScope;
  String get scopeAllDocs;
  String scopeSelectedDocs(int count);
  String docProcessingWarning(String title);
  String get errorLoadingDocVersion;
  String get sessionExpired;
  String get queryError;

  // Snap & Ask
  String get snapHeroTitle;
  String get snapHeroSubtitle;
  String get snapUploadPhoto;
  String get snapCapturePhoto;
  String get snapLoading;
  String get snapInputPlaceholder;
  String get snapAddPhotoFirst;
  String get snapMachineCodeHint;
  String get snapSessionExpired;
  String get snapServiceUnavailable;
  String get snapAnalysisFailed;
  String get snapMockWarning;
  String get qrComingSoon;
  String get selectImageBeforeAsking;
  String get scanQrDesc;
  String get addDevicePhoto;
  String get takePhoto;
  String get takePhotoDesc;
  String get uploadPhoto;
  String get uploadPhotoDescWeb;
  String get uploadPhotoDescMobile;
  String get scanQrCode;
  String get noSnapPhotos;
  String get noSnapPhotosDesc;
  String get selectImageToAsk;
  String get noQuestionsYet;
  String get typeQuestionBelow;
  String get machineCodeHint;
  String get snapTooltip;
  String get askAboutDevicePhoto;
  String get addImageFirstToAsk;

  // Documents & Upload
  String get documentsTitle;
  String get documentsSubtitle;
  String get uploadNewDocument;
  String get uploadDocDesc;
  String get searchDocsPlaceholder;
  String get sortBy;
  String get sortNewest;
  String get sortOldest;
  String get sortTitleAZ;
  String get sortTitleZA;
  String get sortCategory;
  String get allCategories;
  String get allRoles;
  String get docTableTitle;
  String get docTableCategory;
  String get docTableMachineCode;
  String get docTableMinRole;
  String get docTableUpdated;
  String get docTableActions;
  String get docTableVersions;
  String get noDocsFound;
  String get noDocsFoundDesc;
  String get uploadSuccessSnackbar;
  String get fileRequired;
  String get titleRequired;
  String get categoryRequired;
  String get selectPdfFile;
  String get changeFile;
  String get uploading;
  String get submitUpload;

  // Document Detail & OCR Dialog
  String get documentDetail;
  String get deleteDocument;
  String get confirmDelete;
  String deleteConfirmDesc(String title);
  String get deleteSuccess;
  String deleteFailed(String err);
  String get loadDetailFailed;
  String get versionsList;
  String get noVersions;
  String versionNumber(int v);
  String get viewOriginalPdf;
  String get viewOcrText;
  String get loadingPdf;
  String get invalidBinaryData;
  String downloadPdfFailed(String err);
  String ocrDialogTitle(String name);
  String get loadingOcrData;
  String loadOcrFailed(String err);
  String get noOcrData;
  String get searchOcrKeyword;
  String get noOcrPagesMatch;
  String copyPage(int page);
  String pageCopied(int page);
  String get blankPageNotice;
  String get copyAllOcr;
  String get allOcrCopied;
  String pageNumber(int page);
  String get machineCode;
  String get category;
  String get minRole;
  String get description;
  String get createdAt;
  String get updatedAt;

  // Profile & Password
  String get profileTitle;
  String get usernameLabel;
  String get fullNameLabel;
  String get emailLabel;
  String get roleLabel;
  String get changePassword;
  String get currentPassword;
  String get newPassword;
  String get confirmNewPassword;
  String get currentPasswordRequired;
  String get newPasswordMinLength;
  String get passwordsDoNotMatch;
  String get changePasswordSuccess;
  String get changePasswordError;
  String get saveChanges;

  // History & Feedback
  String get historyTitle;
  String get refresh;
  String get noHistoryTitle;
  String get noHistorySubtitle;
  String get feedbackRecordedHelpful;
  String get feedbackRecordedUnhelpful;
  String get feedbackFailed;
  String get photoSource;

  // Admin & Analytics
  String get adminManagement;
  String get adminSubtitle;
  String get adminUserManagement;
  String get adminAnalytics;
  String get createUser;
  String get createUserTitle;
  String get createUserDialogTitle;
  String get analyticsTab;
  String get usersTab;
  String get searchUsersPlaceholder;
  String get totalUsers;
  String get activeUsers;
  String get userCreatedSuccess;
  String get analyticsHeadline;
  String get analyticsSubtitle;
  String get queriesTotal;
  String get totalQueriesTitle;
  String get avgConfidence;
  String get avgConfidenceTitle;
  String get avgLatencyTitle;
  String get guardrailLockedTitle;
  String get guardrailInterventions;
  String get activeSessions;

  // Common & Errors
  String get forbiddenTitle;
  String get forbiddenDesc;
  String get backToSearch;
  String get cancel;
  String get clear;
  String get delete;
  String get close;
  String get retry;
  String get error;
  String get loading;
  String get unknown;

  factory AppStrings.of(AppLocale locale) {
    switch (locale) {
      case AppLocale.vi:
        return const AppStringsVi();
      case AppLocale.en:
        return const AppStringsEn();
    }
  }
}

class AppStringsVi implements AppStrings {
  const AppStringsVi();

  @override
  String get appTitle => 'DCID';
  @override
  String get appSubtitle => 'Docs';
  @override
  String get appFullName => 'Hệ thống Tri thức & Vận hành Công nghiệp DCID';
  @override
  String get appTagline => 'Cơ sở tri thức AI Công nghiệp';

  @override
  String get loginHeadline => 'Đăng nhập để truy cập tài liệu kỹ thuật & trợ lý AI';
  @override
  String get username => 'Tên đăng nhập';
  @override
  String get password => 'Mật khẩu';
  @override
  String get signIn => 'Đăng nhập';
  @override
  String get authFailed => 'Đăng nhập thất bại';
  @override
  String get usernameRequired => 'Vui lòng nhập tên đăng nhập';
  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get navDocuMind => 'DocuMind';
  @override
  String get navSnapAsk => 'Snap & Ask';
  @override
  String get navDocuments => 'Tài liệu';
  @override
  String get navAdmin => 'Quản trị';
  @override
  String get newChat => 'Đoạn chat mới';
  @override
  String get recents => 'Gần đây';
  @override
  String get profileTooltip => 'Hồ sơ cá nhân';
  @override
  String get profileMenuTooltip => 'Hồ sơ cá nhân & Đổi mật khẩu';
  @override
  String get historyTooltip => 'Lịch sử câu hỏi';
  @override
  String get logoutTooltip => 'Đăng xuất';
  @override
  String get expandSidebar => 'Mở rộng thanh bên';
  @override
  String get collapseSidebar => 'Thu gọn thanh bên';
  @override
  String get switchToLight => 'Chuyển sang Giao diện Sáng';
  @override
  String get switchToDark => 'Chuyển sang Giao diện Tối';
  @override
  String get switchLanguage => 'Chuyển đổi ngôn ngữ (Tiếng Việt / English)';
  @override
  String get currentLanguage => 'Ngôn ngữ: Tiếng Việt';

  @override
  String get roleOperator => 'Vận hành (Operator)';
  @override
  String get roleEngineer => 'Kỹ sư (Engineer)';
  @override
  String get roleQaAdmin => 'QA / Admin';
  @override
  String get roleAdmin => 'Quản trị viên';

  @override
  String get searchHeroTitle => 'DCID Docs';
  @override
  String get searchHeroSubtitle => 'Trợ lý tri thức kỹ thuật & quy trình công nghiệp AI';
  @override
  String get searchPlaceholderAll => 'Hỏi về SOP, thông số kỹ thuật, bản vẽ (Tất cả tài liệu)…';
  @override
  String searchPlaceholderSelected(int count) => 'Hỏi trong $count tài liệu đã chọn…';
  @override
  String get insufficientConfidenceBanner => '⚠ Độ tin cậy dữ liệu chưa đủ cao.\nCâu trả lời được tổng hợp với độ tin cậy thấp. Vui lòng đối chiếu với tài liệu chính thức trước khi thực hiện thao tác.';
  @override
  String get lockedAnswerWarning => '⚠ Độ tin cậy dữ liệu chưa đủ cao.\nCâu trả lời được khóa do độ tin cậy thấp. Vui lòng đối chiếu với tài liệu chính thức.';
  @override
  String get directDataExtraction => 'Trích xuất dữ liệu trực tiếp';
  @override
  String get reasoningMode => 'Chế độ suy luận chi tiết';
  @override
  String get referenceSources => 'Tài liệu tham khảo';
  @override
  String get copy => 'Sao chép';
  @override
  String get copied => 'Đã sao chép';
  @override
  String get copyAnswerSuccess => 'Đã sao chép nội dung câu trả lời vào clipboard';
  @override
  String get copySuccessSnackbar => 'Đã sao chép nội dung câu trả lời vào clipboard';
  @override
  String get wasAnswerHelpful => 'Câu trả lời có hữu ích không?';
  @override
  String get feedbackThanks => 'Cảm ơn phản hồi của bạn!';
  @override
  String get thankYouFeedback => 'Cảm ơn phản hồi của bạn!';
  @override
  String get helpful => 'Hữu ích';
  @override
  String get notHelpful => 'Chưa chuẩn';
  @override
  String get citations => 'Tài liệu trích dẫn';
  @override
  String get confidence => 'Độ tin cậy';
  @override
  String get aiDisclaimer => 'Cơ sở tri thức AI  •  Nội dung do AI tạo, vui lòng kiểm tra lại với tài liệu chính thức trước khi vận hành';
  @override
  String get allDocsScope => 'Tất cả tài liệu';
  @override
  String get clearScope => 'Bỏ chọn';
  @override
  String get scopeAllDocs => 'Phạm vi: Tất cả tài liệu';
  @override
  String scopeSelectedDocs(int count) => 'Phạm vi: $count tài liệu đã chọn';
  @override
  String docProcessingWarning(String title) => 'Tài liệu "$title" đang trong quá trình xử lý và chưa thể dùng để tra cứu.';
  @override
  String get errorLoadingDocVersion => 'Không tải được phiên bản tài liệu. Vui lòng thử lại.';
  @override
  String get sessionExpired => 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.';
  @override
  String get queryError => 'Không thể hoàn tất truy vấn. Vui lòng kiểm tra kết nối.';

  @override
  String get snapHeroTitle => 'Chẩn đoán Hình ảnh & Hỏi đáp AI';
  @override
  String get snapHeroSubtitle => 'Chụp hoặc tải ảnh tem máy, thông số, sự cố để tra cứu quy trình SOP tức thì';
  @override
  String get snapUploadPhoto => 'Tải lên ảnh thiết bị';
  @override
  String get snapCapturePhoto => 'Chụp / Tải lên ảnh thiết bị';
  @override
  String get snapLoading => 'Đang tải lên & phân tích...';
  @override
  String get snapInputPlaceholder => 'Hỏi về bức ảnh thiết bị này…';
  @override
  String get snapAddPhotoFirst => 'Vui lòng thêm ảnh thiết bị trước khi đặt câu hỏi…';
  @override
  String get snapMachineCodeHint => 'Mã máy (tùy chọn — vd: CNC-01)';
  @override
  String get snapSessionExpired => '⚠️ **Phiên đăng nhập đã hết hạn.** Vui lòng đăng nhập lại trước khi phân tích ảnh.';
  @override
  String get snapServiceUnavailable => '⚠️ **Không thể kết nối dịch vụ phân tích ảnh.** Vui lòng kiểm tra backend và AI service rồi thử lại.';
  @override
  String get snapAnalysisFailed => '⚠️ **Phân tích ảnh thất bại.** Máy chủ không trả về kết quả hợp lệ; vui lòng thử lại.';
  @override
  String get snapMockWarning => 'Không có dữ liệu OCR hoặc thông số kỹ thuật nào được tìm thấy.';
  @override
  String get qrComingSoon => 'Tính năng quét mã QR đang được phát triển — vui lòng nhập mã máy thủ công.';
  @override
  String get selectImageBeforeAsking => 'Vui lòng chọn hoặc chụp ảnh thiết bị trước khi hỏi';
  @override
  String get scanQrDesc => 'Quét mã QR để nhận diện thiết bị nhanh chóng';
  @override
  String get addDevicePhoto => 'Thêm ảnh thiết bị';
  @override
  String get takePhoto => 'Chụp ảnh';
  @override
  String get takePhotoDesc => 'Mở camera để chụp ảnh thiết bị / tem máy';
  @override
  String get uploadPhoto => 'Tải lên ảnh';
  @override
  String get uploadPhotoDescWeb => 'Chọn tệp ảnh từ máy tính của bạn';
  @override
  String get uploadPhotoDescMobile => 'Chọn ảnh có sẵn từ thư viện ảnh';
  @override
  String get scanQrCode => 'Quét mã QR máy';
  @override
  String get noSnapPhotos => 'Chưa có ảnh thiết bị nào';
  @override
  String get noSnapPhotosDesc => 'Nhấn nút + bên dưới để chụp ảnh,\ntải từ thư viện hoặc quét mã QR thiết bị.';
  @override
  String get selectImageToAsk => 'Chọn một ảnh để bắt đầu đặt câu hỏi';
  @override
  String get noQuestionsYet => 'Chưa có câu hỏi nào cho ảnh này';
  @override
  String get typeQuestionBelow => 'Nhập câu hỏi bên dưới để bắt đầu phân tích';
  @override
  String get machineCodeHint => 'Mã máy (tùy chọn — vd: CNC-01)';
  @override
  String get snapTooltip => 'Thêm ảnh hoặc quét mã QR';
  @override
  String get askAboutDevicePhoto => 'Hỏi về bức ảnh thiết bị này…';
  @override
  String get addImageFirstToAsk => 'Thêm ảnh thiết bị trước khi đặt câu hỏi…';

  @override
  String get documentsTitle => 'Quản trị Tài liệu Kỹ thuật';
  @override
  String get documentsSubtitle => 'Quy trình SOP, bản vẽ kỹ thuật, sổ tay hướng dẫn kèm OCR & theo dõi phiên bản';
  @override
  String get uploadNewDocument => 'Tải lên tài liệu mới';
  @override
  String get uploadDocDesc => 'Thêm quy trình SOP, bản vẽ kỹ thuật hoặc hướng dẫn sử dụng vào DCID';
  @override
  String get searchDocsPlaceholder => 'Tìm kiếm theo tên, mã máy, danh mục…';
  @override
  String get sortBy => 'Sắp xếp theo';
  @override
  String get sortNewest => 'Mới nhất trước';
  @override
  String get sortOldest => 'Cũ nhất trước';
  @override
  String get sortTitleAZ => 'Tên A→Z';
  @override
  String get sortTitleZA => 'Tên Z→A';
  @override
  String get sortCategory => 'Danh mục / Mã máy';
  @override
  String get allCategories => 'Tất cả danh mục';
  @override
  String get allRoles => 'Mọi vai trò';
  @override
  String get docTableTitle => 'Tên tài liệu';
  @override
  String get docTableCategory => 'Danh mục';
  @override
  String get docTableMachineCode => 'Mã máy';
  @override
  String get docTableMinRole => 'Vai trò tối thiểu';
  @override
  String get docTableUpdated => 'Cập nhật';
  @override
  String get docTableActions => 'Thao tác';
  @override
  String get docTableVersions => 'Phiên bản';
  @override
  String get noDocsFound => 'Không tìm thấy tài liệu nào';
  @override
  String get noDocsFoundDesc => 'Thử điều chỉnh từ khóa tìm kiếm hoặc bộ lọc danh mục/vai trò.';
  @override
  String get uploadSuccessSnackbar => 'Đã tải lên — Tiến trình xử lý OCR đã bắt đầu...';
  @override
  String get fileRequired => 'Vui lòng chọn tệp tài liệu PDF';
  @override
  String get titleRequired => 'Vui lòng nhập tên tài liệu';
  @override
  String get categoryRequired => 'Vui lòng chọn danh mục';
  @override
  String get selectPdfFile => 'Chọn tệp tài liệu PDF';
  @override
  String get changeFile => 'Đổi tệp';
  @override
  String get uploading => 'Đang tải lên...';
  @override
  String get submitUpload => 'Tải lên & Xử lý OCR';

  @override
  String get documentDetail => 'Chi tiết tài liệu';
  @override
  String get deleteDocument => 'Xóa tài liệu';
  @override
  String get confirmDelete => 'Xác nhận xóa tài liệu';
  @override
  String deleteConfirmDesc(String title) => 'Bạn có chắc chắn muốn xóa "$title"? Hành động này không thể hoàn tác.';
  @override
  String get deleteSuccess => 'Đã xóa tài liệu thành công.';
  @override
  String deleteFailed(String err) => 'Không thể xóa tài liệu: $err';
  @override
  String get loadDetailFailed => 'Không tải được chi tiết tài liệu.';
  @override
  String get versionsList => 'Danh sách phiên bản';
  @override
  String get noVersions => 'Chưa có phiên bản nào.';
  @override
  String versionNumber(int v) => 'Phiên bản $v';
  @override
  String get viewOriginalPdf => 'Xem PDF gốc';
  @override
  String get viewOcrText => 'Xem chữ OCR';
  @override
  String get loadingPdf => 'Đang tải file PDF...';
  @override
  String get invalidBinaryData => 'Dữ liệu trả về không đúng định dạng binary';
  @override
  String downloadPdfFailed(String err) => 'Không tải được file PDF: $err';
  @override
  String ocrDialogTitle(String name) => 'Văn bản OCR ($name)';
  @override
  String get loadingOcrData => 'Đang tải dữ liệu OCR...';
  @override
  String loadOcrFailed(String err) => 'Không tải được dữ liệu OCR:\n$err';
  @override
  String get noOcrData => 'Chưa có dữ liệu OCR cho phiên bản này.';
  @override
  String get searchOcrKeyword => 'Tìm từ khóa trong nội dung OCR...';
  @override
  String get noOcrPagesMatch => 'Không tìm thấy trang nào khớp với từ khóa.';
  @override
  String copyPage(int page) => 'Sao chép trang $page';
  @override
  String pageCopied(int page) => 'Đã sao chép nội dung trang $page';
  @override
  String get blankPageNotice => '(Trang trắng / không có chữ)';
  @override
  String get copyAllOcr => 'Sao chép tất cả';
  @override
  String get allOcrCopied => 'Đã sao chép toàn bộ nội dung OCR vào clipboard';
  @override
  String pageNumber(int page) => 'Trang $page';
  @override
  String get machineCode => 'Mã máy';
  @override
  String get category => 'Danh mục';
  @override
  String get minRole => 'Vai trò tối thiểu';
  @override
  String get description => 'Mô tả';
  @override
  String get createdAt => 'Tạo lúc';
  @override
  String get updatedAt => 'Cập nhật lúc';

  @override
  String get profileTitle => 'Hồ sơ cá nhân';
  @override
  String get usernameLabel => 'Tên đăng nhập';
  @override
  String get fullNameLabel => 'Họ và tên';
  @override
  String get emailLabel => 'Email';
  @override
  String get roleLabel => 'Vai trò';
  @override
  String get changePassword => 'Đổi mật khẩu';
  @override
  String get currentPassword => 'Mật khẩu hiện tại';
  @override
  String get newPassword => 'Mật khẩu mới';
  @override
  String get confirmNewPassword => 'Nhập lại mật khẩu mới';
  @override
  String get currentPasswordRequired => 'Vui lòng nhập mật khẩu hiện tại';
  @override
  String get newPasswordMinLength => 'Mật khẩu mới tối thiểu 6 ký tự';
  @override
  String get passwordsDoNotMatch => 'Mật khẩu xác nhận không khớp';
  @override
  String get changePasswordSuccess => 'Đổi mật khẩu thành công.';
  @override
  String get changePasswordError => 'Lỗi đổi mật khẩu';
  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get historyTitle => 'Lịch sử câu hỏi';
  @override
  String get refresh => 'Làm mới';
  @override
  String get noHistoryTitle => 'Chưa có câu hỏi nào';
  @override
  String get noHistorySubtitle => 'Các câu hỏi bạn đã hỏi trợ lý AI sẽ xuất hiện tại đây.';
  @override
  String get feedbackRecordedHelpful => '👍 Cảm ơn phản hồi của bạn!';
  @override
  String get feedbackRecordedUnhelpful => '👎 Đã ghi nhận phản hồi.';
  @override
  String get feedbackFailed => 'Không gửi được phản hồi. Thử lại sau.';
  @override
  String get photoSource => 'Nguồn ảnh';

  @override
  String get adminManagement => 'Quản trị hệ thống';
  @override
  String get adminSubtitle => 'Quản lý tài khoản người dùng, phân quyền vai trò và theo dõi hệ thống';
  @override
  String get adminUserManagement => 'Quản lý người dùng';
  @override
  String get adminAnalytics => 'Báo cáo & Phân tích hệ thống';
  @override
  String get createUser => 'Tạo người dùng';
  @override
  String get createUserTitle => 'Tạo tài khoản người dùng mới';
  @override
  String get createUserDialogTitle => 'Tạo tài khoản người dùng mới';
  @override
  String get analyticsTab => 'Báo cáo & KPIs';
  @override
  String get usersTab => 'Tài khoản người dùng';
  @override
  String get searchUsersPlaceholder => 'Tìm người dùng theo tên, tài khoản, email…';
  @override
  String get totalUsers => 'Tổng người dùng';
  @override
  String get activeUsers => 'Đang hoạt động';
  @override
  String get userCreatedSuccess => 'Tạo người dùng thành công';
  @override
  String get analyticsHeadline => 'Chỉ số & Hiệu suất Hệ thống';
  @override
  String get analyticsSubtitle => 'Số liệu thời gian thực, mức độ tuân thủ quy chuẩn và hiệu năng truy vấn.';
  @override
  String get queriesTotal => 'Tổng câu hỏi';
  @override
  String get totalQueriesTitle => 'Tổng truy vấn';
  @override
  String get avgConfidence => 'Độ tin cậy TB';
  @override
  String get avgConfidenceTitle => 'Độ tin cậy trung bình';
  @override
  String get avgLatencyTitle => 'Độ trễ trung bình';
  @override
  String get guardrailLockedTitle => 'Khóa an toàn (Guardrail)';
  @override
  String get guardrailInterventions => 'Can thiệp quy chuẩn';
  @override
  String get activeSessions => 'Phiên hoạt động';

  @override
  String get forbiddenTitle => 'Không có quyền truy cập';
  @override
  String get forbiddenDesc => 'Bạn không có quyền truy cập vào mục này.';
  @override
  String get backToSearch => 'Về trang DocuMind';
  @override
  String get cancel => 'Hủy';
  @override
  String get clear => 'Xóa';
  @override
  String get delete => 'Xóa';
  @override
  String get close => 'Đóng';
  @override
  String get retry => 'Thử lại';
  @override
  String get error => 'Lỗi';
  @override
  String get loading => 'Đang tải...';
  @override
  String get unknown => 'Không xác định';
}

class AppStringsEn implements AppStrings {
  const AppStringsEn();

  @override
  String get appTitle => 'DCID';
  @override
  String get appSubtitle => 'Docs';
  @override
  String get appFullName => 'Digital Cognitive InDustrial System';
  @override
  String get appTagline => 'AI Knowledge Base';

  @override
  String get loginHeadline => 'Sign in to access industrial documents & AI assistant';
  @override
  String get username => 'Username';
  @override
  String get password => 'Password';
  @override
  String get signIn => 'Sign In';
  @override
  String get authFailed => 'Authentication failed';
  @override
  String get usernameRequired => 'Please enter username';
  @override
  String get passwordRequired => 'Please enter password';

  @override
  String get navDocuMind => 'DocuMind';
  @override
  String get navSnapAsk => 'Snap & Ask';
  @override
  String get navDocuments => 'Documents';
  @override
  String get navAdmin => 'Admin';
  @override
  String get newChat => 'New Chat';
  @override
  String get recents => 'Recents';
  @override
  String get profileTooltip => 'User Profile';
  @override
  String get profileMenuTooltip => 'User Profile & Change Password';
  @override
  String get historyTooltip => 'Query History';
  @override
  String get logoutTooltip => 'Sign Out';
  @override
  String get expandSidebar => 'Expand sidebar';
  @override
  String get collapseSidebar => 'Collapse sidebar';
  @override
  String get switchToLight => 'Switch to Light Mode';
  @override
  String get switchToDark => 'Switch to Dark Mode';
  @override
  String get switchLanguage => 'Switch Language (Tiếng Việt / English)';
  @override
  String get currentLanguage => 'Language: English';

  @override
  String get roleOperator => 'Operator';
  @override
  String get roleEngineer => 'Engineer';
  @override
  String get roleQaAdmin => 'QA / Admin';
  @override
  String get roleAdmin => 'Admin';

  @override
  String get searchHeroTitle => 'DCID Docs';
  @override
  String get searchHeroSubtitle => 'AI-powered industrial knowledge assistant';
  @override
  String get searchPlaceholderAll => 'Ask about SOPs, specs, drawings (All documents)…';
  @override
  String searchPlaceholderSelected(int count) => 'Ask about $count selected document(s)…';
  @override
  String get insufficientConfidenceBanner => '⚠ Insufficient data confidence.\nAnswer is synthesized with low confidence. Please verify with official documentation before operating.';
  @override
  String get lockedAnswerWarning => '⚠ Insufficient data confidence.\nAnswer is locked due to low confidence. Please verify with official documentation.';
  @override
  String get directDataExtraction => 'Direct Data Extraction';
  @override
  String get reasoningMode => 'Detailed Reasoning Mode';
  @override
  String get referenceSources => 'Reference Sources';
  @override
  String get copy => 'Copy';
  @override
  String get copied => 'Copied';
  @override
  String get copyAnswerSuccess => 'Answer copied to clipboard';
  @override
  String get copySuccessSnackbar => 'Answer copied to clipboard';
  @override
  String get wasAnswerHelpful => 'Was this answer helpful?';
  @override
  String get feedbackThanks => 'Thank you for your feedback!';
  @override
  String get thankYouFeedback => 'Thank you for your feedback!';
  @override
  String get helpful => 'Helpful';
  @override
  String get notHelpful => 'Not helpful';
  @override
  String get citations => 'Citations';
  @override
  String get confidence => 'Confidence';
  @override
  String get aiDisclaimer => 'AI Knowledge Base  •  AI-generated content, please double-check with official documents before operating';
  @override
  String get allDocsScope => 'All Documents';
  @override
  String get clearScope => 'Clear selection';
  @override
  String get scopeAllDocs => 'Scope: All Documents (Global RAG)';
  @override
  String scopeSelectedDocs(int count) => 'Scope: $count document(s) selected';
  @override
  String docProcessingWarning(String title) => 'Document "$title" is still processing and cannot be used for AI queries yet.';
  @override
  String get errorLoadingDocVersion => 'Could not load document version. Please try again.';
  @override
  String get sessionExpired => 'Session expired, please sign in again.';
  @override
  String get queryError => 'Unable to complete query. Please check backend/AI connection.';

  @override
  String get snapHeroTitle => 'Visual Diagnostic & AI Q&A';
  @override
  String get snapHeroSubtitle => 'Upload or capture machine plates, errors, or schematics to query instant SOPs';
  @override
  String get snapUploadPhoto => 'Upload Device Photo';
  @override
  String get snapCapturePhoto => 'Take / Upload Photo';
  @override
  String get snapLoading => 'Uploading & Analyzing...';
  @override
  String get snapInputPlaceholder => 'Ask about this device photo…';
  @override
  String get snapAddPhotoFirst => 'Add an image first to start asking…';
  @override
  String get snapMachineCodeHint => 'Machine Code (optional — e.g. CNC-01)';
  @override
  String get snapSessionExpired => '⚠️ **Session expired.** Please sign in again before analyzing images.';
  @override
  String get snapServiceUnavailable => '⚠️ **Could not connect to image analysis service.** Please check backend and AI service then retry.';
  @override
  String get snapAnalysisFailed => '⚠️ **Image analysis failed.** Server returned an invalid result; please retry.';
  @override
  String get snapMockWarning => 'No real OCR or specs were found for mock fallback.';
  @override
  String get qrComingSoon => 'QR scanner coming soon — enter the machine code manually for now.';
  @override
  String get selectImageBeforeAsking => 'Please select an image before asking';
  @override
  String get scanQrDesc => 'Scan a QR code to identify the machine';
  @override
  String get addDevicePhoto => 'Add Device Image';
  @override
  String get takePhoto => 'Take Photo';
  @override
  String get takePhotoDesc => 'Open camera to photograph the device';
  @override
  String get uploadPhoto => 'Upload Photo';
  @override
  String get uploadPhotoDescWeb => 'Select an image file from your computer';
  @override
  String get uploadPhotoDescMobile => 'Choose an existing photo from your gallery';
  @override
  String get scanQrCode => 'Scan Machine QR';
  @override
  String get noSnapPhotos => 'No device photos yet';
  @override
  String get noSnapPhotosDesc => 'Tap the + button below to take a photo,\nupload from gallery, or scan a machine QR code.';
  @override
  String get selectImageToAsk => 'Select an image to start asking questions';
  @override
  String get noQuestionsYet => 'No questions yet for this image';
  @override
  String get typeQuestionBelow => 'Type your question below to start the analysis';
  @override
  String get machineCodeHint => 'Machine Code (optional — e.g. CNC-01)';
  @override
  String get snapTooltip => 'Add image or scan QR';
  @override
  String get askAboutDevicePhoto => 'Ask about this device photo…';
  @override
  String get addImageFirstToAsk => 'Add an image first to start asking…';

  @override
  String get documentsTitle => 'Industrial Document Governance';
  @override
  String get documentsSubtitle => 'SOPs, schematics, engineering specs with OCR & version tracking';
  @override
  String get uploadNewDocument => 'Upload New Document';
  @override
  String get uploadDocDesc => 'Add SOPs, drawings, manuals or specs to DCID';
  @override
  String get searchDocsPlaceholder => 'Search documents by title, code, category…';
  @override
  String get sortBy => 'Sort by';
  @override
  String get sortNewest => 'Newest first';
  @override
  String get sortOldest => 'Oldest first';
  @override
  String get sortTitleAZ => 'Title A→Z';
  @override
  String get sortTitleZA => 'Title Z→A';
  @override
  String get sortCategory => 'Category / Code';
  @override
  String get allCategories => 'All Categories';
  @override
  String get allRoles => 'All Roles';
  @override
  String get docTableTitle => 'Document Title';
  @override
  String get docTableCategory => 'Category';
  @override
  String get docTableMachineCode => 'Machine Code';
  @override
  String get docTableMinRole => 'Min Role';
  @override
  String get docTableUpdated => 'Last Updated';
  @override
  String get docTableActions => 'Actions';
  @override
  String get docTableVersions => 'Versions';
  @override
  String get noDocsFound => 'No documents found';
  @override
  String get noDocsFoundDesc => 'Try adjusting your search query or role filters.';
  @override
  String get uploadSuccessSnackbar => 'Uploaded — OCR processing started...';
  @override
  String get fileRequired => 'Please select a document file (PDF)';
  @override
  String get titleRequired => 'Document title is required';
  @override
  String get categoryRequired => 'Category is required';
  @override
  String get selectPdfFile => 'Select PDF Document';
  @override
  String get changeFile => 'Change File';
  @override
  String get uploading => 'Uploading...';
  @override
  String get submitUpload => 'Upload & Process OCR';

  @override
  String get documentDetail => 'Document Details';
  @override
  String get deleteDocument => 'Delete Document';
  @override
  String get confirmDelete => 'Confirm Document Deletion';
  @override
  String deleteConfirmDesc(String title) => 'Are you sure you want to delete "$title"? This action cannot be undone.';
  @override
  String get deleteSuccess => 'Document deleted successfully.';
  @override
  String deleteFailed(String err) => 'Failed to delete document: $err';
  @override
  String get loadDetailFailed => 'Failed to load document details.';
  @override
  String get versionsList => 'Versions';
  @override
  String get noVersions => 'No versions available.';
  @override
  String versionNumber(int v) => 'Version $v';
  @override
  String get viewOriginalPdf => 'View Original PDF';
  @override
  String get viewOcrText => 'View OCR Text';
  @override
  String get loadingPdf => 'Downloading PDF file...';
  @override
  String get invalidBinaryData => 'Returned data is not valid binary';
  @override
  String downloadPdfFailed(String err) => 'Could not load PDF file: $err';
  @override
  String ocrDialogTitle(String name) => 'OCR Text ($name)';
  @override
  String get loadingOcrData => 'Loading OCR extracted text...';
  @override
  String loadOcrFailed(String err) => 'Failed to load OCR data:\n$err';
  @override
  String get noOcrData => 'No OCR data found for this version.';
  @override
  String get searchOcrKeyword => 'Search keyword in OCR content...';
  @override
  String get noOcrPagesMatch => 'No pages matched your search keyword.';
  @override
  String copyPage(int page) => 'Copy page $page';
  @override
  String pageCopied(int page) => 'Page $page content copied';
  @override
  String get blankPageNotice => '(Blank page / no text)';
  @override
  String get copyAllOcr => 'Copy All';
  @override
  String get allOcrCopied => 'All OCR text copied to clipboard';
  @override
  String pageNumber(int page) => 'Page $page';
  @override
  String get machineCode => 'Machine Code';
  @override
  String get category => 'Category';
  @override
  String get minRole => 'Min Role';
  @override
  String get description => 'Description';
  @override
  String get createdAt => 'Created At';
  @override
  String get updatedAt => 'Updated At';

  @override
  String get profileTitle => 'User Profile';
  @override
  String get usernameLabel => 'Username';
  @override
  String get fullNameLabel => 'Full Name';
  @override
  String get emailLabel => 'Email';
  @override
  String get roleLabel => 'Role';
  @override
  String get changePassword => 'Change Password';
  @override
  String get currentPassword => 'Current Password';
  @override
  String get newPassword => 'New Password';
  @override
  String get confirmNewPassword => 'Confirm New Password';
  @override
  String get currentPasswordRequired => 'Please enter current password';
  @override
  String get newPasswordMinLength => 'New password must be at least 6 characters';
  @override
  String get passwordsDoNotMatch => 'Confirmation password does not match';
  @override
  String get changePasswordSuccess => 'Password changed successfully.';
  @override
  String get changePasswordError => 'Failed to change password';
  @override
  String get saveChanges => 'Save Changes';

  @override
  String get historyTitle => 'Query History';
  @override
  String get refresh => 'Refresh';
  @override
  String get noHistoryTitle => 'No queries yet';
  @override
  String get noHistorySubtitle => 'Questions you ask the AI assistant will appear here.';
  @override
  String get feedbackRecordedHelpful => '👍 Thank you for your feedback!';
  @override
  String get feedbackRecordedUnhelpful => '👎 Feedback recorded.';
  @override
  String get feedbackFailed => 'Could not submit feedback. Try again later.';
  @override
  String get photoSource => 'Photo Source';

  @override
  String get adminManagement => 'System Administration';
  @override
  String get adminSubtitle => 'User accounts, role assignment, and access control';
  @override
  String get adminUserManagement => 'User Management';
  @override
  String get adminAnalytics => 'System Analytics & KPIs';
  @override
  String get createUser => 'Create User';
  @override
  String get createUserTitle => 'Create New User Account';
  @override
  String get createUserDialogTitle => 'Create New User Account';
  @override
  String get analyticsTab => 'Analytics & KPIs';
  @override
  String get usersTab => 'User Accounts';
  @override
  String get searchUsersPlaceholder => 'Search users by name, username, email…';
  @override
  String get totalUsers => 'Total Users';
  @override
  String get activeUsers => 'Active';
  @override
  String get userCreatedSuccess => 'User created successfully';
  @override
  String get analyticsHeadline => 'System Analytics & KPIs';
  @override
  String get analyticsSubtitle => 'Real-time metrics, guardrail adherence, and query performance.';
  @override
  String get queriesTotal => 'Total Queries';
  @override
  String get totalQueriesTitle => 'Total Queries';
  @override
  String get avgConfidence => 'Avg Confidence';
  @override
  String get avgConfidenceTitle => 'Avg Confidence';
  @override
  String get avgLatencyTitle => 'Avg Latency';
  @override
  String get guardrailLockedTitle => 'Guardrail Locked';
  @override
  String get guardrailInterventions => 'Guardrail Interventions';
  @override
  String get activeSessions => 'Active Sessions';

  @override
  String get forbiddenTitle => 'Access Restricted';
  @override
  String get forbiddenDesc => 'You do not have permission to view this section.';
  @override
  String get backToSearch => 'Back to DocuMind';
  @override
  String get cancel => 'Cancel';
  @override
  String get clear => 'Clear';
  @override
  String get delete => 'Delete';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Retry';
  @override
  String get error => 'Error';
  @override
  String get loading => 'Loading...';
  @override
  String get unknown => 'Unknown';
}
