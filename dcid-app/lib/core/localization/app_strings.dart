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
  String get searchHistoryPlaceholder;
  String get filterAllDates;
  String get filterToday;
  String get filter7Days;
  String get filter30Days;
  String get filterCustomDate;
  String get filterAllFeedback;
  String get filterHelpful;
  String get filterNotHelpful;
  String get filterUnrated;
  String get filterLocked;
  String get clearFilters;
  String get noMatchingHistory;
  String get noMatchingHistoryDesc;
  String get copyQuestionSuccess;
  String showingHistoryCount(int current, int total);
  String get showMore;
  String get showLess;
  String get feedbackNotePrompt;

  // Admin & Analytics
  String get adminManagement;
  String get adminSubtitle;
  String get adminUserManagement;
  String get adminAnalytics;
  String get feedbackTab;
  String get adminFeedbacksTitle;
  String get noFeedbacksFound;
  String get feedbackRating;
  String get feedbackNoteLabel;
  String get feedbackUserLabel;
  String get totalFeedbacks;
  String get helpfulCountLabel;
  String get notHelpfulCountLabel;
  String get satisfactionRate;
  String get searchFeedbackPlaceholder;
  String get filterAllRatings;
  String get filterHelpfulOnly;
  String get filterNotHelpfulOnly;
  String get columnTime;
  String get columnUser;
  String get columnRating;
  String get columnQuestion;
  String get columnFeedbackNote;
  String get columnConfidence;
  String showingFeedbacksCount(int count);
  String get questionDetailLabel;
  String get answerDetailLabel;
  String get dateRange;
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
      case AppLocale.hi:
        return const AppStringsHi();
      case AppLocale.ja:
        return const AppStringsJa();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vietnamese (Tiếng Việt)
// ─────────────────────────────────────────────────────────────────────────────

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
  String get switchLanguage => 'Chuyển đổi ngôn ngữ';
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
  String get searchHistoryPlaceholder => 'Tìm kiếm theo câu hỏi hoặc câu trả lời...';
  @override
  String get filterAllDates => 'Tất cả';
  @override
  String get filterToday => 'Hôm nay';
  @override
  String get filter7Days => '7 ngày qua';
  @override
  String get filter30Days => '30 ngày qua';
  @override
  String get filterCustomDate => 'Tùy chọn ngày...';
  @override
  String get filterAllFeedback => 'Tất cả phản hồi';
  @override
  String get filterHelpful => '👍 Đã thích';
  @override
  String get filterNotHelpful => '👎 Không thích';
  @override
  String get filterUnrated => '⏳ Chưa đánh giá';
  @override
  String get filterLocked => '🔒 Bị khóa';
  @override
  String get clearFilters => 'Xóa bộ lọc';
  @override
  String get noMatchingHistory => 'Không tìm thấy câu hỏi phù hợp';
  @override
  String get noMatchingHistoryDesc => 'Thử thay đổi từ khóa tìm kiếm hoặc điều chỉnh bộ lọc ngày/trạng thái.';
  @override
  String get copyQuestionSuccess => 'Đã sao chép câu hỏi vào bộ nhớ tạm!';
  @override
  String showingHistoryCount(int current, int total) => 'Hiển thị $current / $total câu hỏi';
  @override
  String get showMore => 'Xem thêm';
  @override
  String get showLess => 'Thu gọn';
  @override
  String get feedbackNotePrompt => 'Góp ý hoặc nêu lý do (tùy chọn):';

  @override
  String get adminManagement => 'Quản trị hệ thống';
  @override
  String get adminSubtitle => 'Quản lý tài khoản người dùng, phân quyền vai trò và theo dõi hệ thống';
  @override
  String get adminUserManagement => 'Quản lý người dùng';
  @override
  String get adminAnalytics => 'Báo cáo & Phân tích hệ thống';
  @override
  String get feedbackTab => 'Đánh giá người dùng';
  @override
  String get adminFeedbacksTitle => 'Nhật ký đánh giá & phản hồi câu trả lời AI';
  @override
  String get noFeedbacksFound => 'Chưa có phản hồi nào từ người dùng';
  @override
  String get feedbackRating => 'Đánh giá';
  @override
  String get feedbackNoteLabel => 'Nội dung góp ý';
  @override
  String get feedbackUserLabel => 'Người dùng';
  @override
  String get totalFeedbacks => 'Tổng đánh giá';
  @override
  String get helpfulCountLabel => 'Hữu ích (👍)';
  @override
  String get notHelpfulCountLabel => 'Không hữu ích (👎)';
  @override
  String get satisfactionRate => 'Tỷ lệ hài lòng';
  @override
  String get searchFeedbackPlaceholder => 'Tìm theo câu hỏi, câu trả lời, người dùng hoặc ghi chú...';
  @override
  String get filterAllRatings => 'Tất cả đánh giá';
  @override
  String get filterHelpfulOnly => '👍 Chỉ hữu ích';
  @override
  String get filterNotHelpfulOnly => '👎 Chỉ không hữu ích';
  @override
  String get columnTime => 'Thời gian';
  @override
  String get columnUser => 'Người dùng';
  @override
  String get columnRating => 'Đánh giá';
  @override
  String get columnQuestion => 'Câu hỏi';
  @override
  String get columnFeedbackNote => 'Ghi chú góp ý';
  @override
  String get columnConfidence => 'Độ tin cậy';
  @override
  String showingFeedbacksCount(int count) => 'Hiển thị $count phản hồi (Nhấn vào hàng để xem chi tiết)';
  @override
  String get questionDetailLabel => 'Câu hỏi:';
  @override
  String get answerDetailLabel => 'Câu trả lời AI:';
  @override
  String get dateRange => 'Khoảng thời gian';
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

// ─────────────────────────────────────────────────────────────────────────────
// English
// ─────────────────────────────────────────────────────────────────────────────

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
  String get switchLanguage => 'Switch Language';
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
  String get searchHistoryPlaceholder => 'Search questions or answer content...';
  @override
  String get filterAllDates => 'All Time';
  @override
  String get filterToday => 'Today';
  @override
  String get filter7Days => 'Last 7 Days';
  @override
  String get filter30Days => 'Last 30 Days';
  @override
  String get filterCustomDate => 'Custom Range...';
  @override
  String get filterAllFeedback => 'All Feedback';
  @override
  String get filterHelpful => '👍 Helpful';
  @override
  String get filterNotHelpful => '👎 Not Helpful';
  @override
  String get filterUnrated => '⏳ Unrated';
  @override
  String get filterLocked => '🔒 Guarded';
  @override
  String get clearFilters => 'Clear Filters';
  @override
  String get noMatchingHistory => 'No matching history found';
  @override
  String get noMatchingHistoryDesc => 'Try adjusting your search keywords or date/status filters.';
  @override
  String get copyQuestionSuccess => 'Question copied to clipboard!';
  @override
  String showingHistoryCount(int current, int total) => 'Showing $current of $total queries';
  @override
  String get showMore => 'Show more';
  @override
  String get showLess => 'Show less';
  @override
  String get feedbackNotePrompt => 'Reason or optional notes:';

  @override
  String get adminManagement => 'System Administration';
  @override
  String get adminSubtitle => 'User accounts, role assignment, and access control';
  @override
  String get adminUserManagement => 'User Management';
  @override
  String get adminAnalytics => 'System Analytics & KPIs';
  @override
  String get feedbackTab => 'User Feedbacks';
  @override
  String get adminFeedbacksTitle => 'User Feedback Logs on AI Answers';
  @override
  String get noFeedbacksFound => 'No user feedback recorded yet';
  @override
  String get feedbackRating => 'Rating';
  @override
  String get feedbackNoteLabel => 'Feedback Notes';
  @override
  String get feedbackUserLabel => 'User';
  @override
  String get totalFeedbacks => 'Total Feedbacks';
  @override
  String get helpfulCountLabel => 'Helpful (👍)';
  @override
  String get notHelpfulCountLabel => 'Not Helpful (👎)';
  @override
  String get satisfactionRate => 'Satisfaction Rate';
  @override
  String get searchFeedbackPlaceholder => 'Search by question, answer, user, or note...';
  @override
  String get filterAllRatings => 'All Ratings';
  @override
  String get filterHelpfulOnly => '👍 Helpful only';
  @override
  String get filterNotHelpfulOnly => '👎 Not Helpful only';
  @override
  String get columnTime => 'Time';
  @override
  String get columnUser => 'User';
  @override
  String get columnRating => 'Rating';
  @override
  String get columnQuestion => 'Question';
  @override
  String get columnFeedbackNote => 'Feedback Note';
  @override
  String get columnConfidence => 'Confidence';
  @override
  String showingFeedbacksCount(int count) => 'Showing $count feedback entries (Click any row for full details)';
  @override
  String get questionDetailLabel => 'Question:';
  @override
  String get answerDetailLabel => 'AI Answer:';
  @override
  String get dateRange => 'Date Range';
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

// ─────────────────────────────────────────────────────────────────────────────
// Hindi (हिन्दी)
// ─────────────────────────────────────────────────────────────────────────────

class AppStringsHi implements AppStrings {
  const AppStringsHi();

  @override
  String get appTitle => 'DCID';
  @override
  String get appSubtitle => 'Docs';
  @override
  String get appFullName => 'DCID डिजिटल कॉग्निटिव इंडस्ट्रियल सिस्टम';
  @override
  String get appTagline => 'औद्योगिक एआई ज्ञान आधार';

  @override
  String get loginHeadline => 'तकनीकी दस्तावेज़ और एआई सहायक तक पहुँचने के लिए साइन इन करें';
  @override
  String get username => 'उपयोगकर्ता नाम';
  @override
  String get password => 'पासवर्ड';
  @override
  String get signIn => 'साइन इन करें';
  @override
  String get authFailed => 'प्रमाणीकरण विफल रहा';
  @override
  String get usernameRequired => 'कृपया उपयोगकर्ता नाम दर्ज करें';
  @override
  String get passwordRequired => 'कृपया पासवर्ड दर्ज करें';

  @override
  String get navDocuMind => 'DocuMind';
  @override
  String get navSnapAsk => 'Snap & Ask';
  @override
  String get navDocuments => 'दस्तावेज़';
  @override
  String get navAdmin => 'व्यवस्थापक';
  @override
  String get newChat => 'नई चैट';
  @override
  String get recents => 'हाल की चैट';
  @override
  String get profileTooltip => 'उपयोगकर्ता प्रोफ़ाइल';
  @override
  String get profileMenuTooltip => 'उपयोगकर्ता प्रोफ़ाइल और पासवर्ड बदलें';
  @override
  String get historyTooltip => 'प्रश्नोत्तरी इतिहास';
  @override
  String get logoutTooltip => 'साइन आउट';
  @override
  String get expandSidebar => 'साइडबार विस्तृत करें';
  @override
  String get collapseSidebar => 'साइडबार संक्षिप्त करें';
  @override
  String get switchToLight => 'लाइट मोड में बदलें';
  @override
  String get switchToDark => 'डार्क मोड में बदलें';
  @override
  String get switchLanguage => 'भाषा बदलें';
  @override
  String get currentLanguage => 'भाषा: हिन्दी';

  @override
  String get roleOperator => 'ऑपरेटर (Operator)';
  @override
  String get roleEngineer => 'इंजीनियर (Engineer)';
  @override
  String get roleQaAdmin => 'क्यूए / व्यवस्थापक (QA / Admin)';
  @override
  String get roleAdmin => 'मुख्य व्यवस्थापक (Admin)';

  @override
  String get searchHeroTitle => 'DCID Docs';
  @override
  String get searchHeroSubtitle => 'एआई-संचालित औद्योगिक ज्ञान और एसओपी सहायक';
  @override
  String get searchPlaceholderAll => 'एसओपी, विनिर्देशों, आरेखों के बारे में पूछें (सभी दस्तावेज़)…';
  @override
  String searchPlaceholderSelected(int count) => 'चयनित $count दस्तावेज़(ओं) में पूछें…';
  @override
  String get insufficientConfidenceBanner => '⚠ अपर्याप्त डेटा सटीकता।\nउत्तर कम विश्वास के साथ तैयार किया गया है। कृपया संचालन से पहले आधिकारिक दस्तावेज़ों से सत्यापित करें।';
  @override
  String get lockedAnswerWarning => '⚠ डेटा विश्वसनीयता अपर्याप्त है। कम विश्वसनीयता के कारण उत्तर लॉक किया गया है। कृपया आधिकारिक दस्तावेज़ देखें।';
  @override
  String get directDataExtraction => 'प्रत्यक्ष डेटा निष्कर्षण';
  @override
  String get reasoningMode => 'विस्तृत तर्क मोड';
  @override
  String get referenceSources => 'संदर्भ स्रोत';
  @override
  String get copy => 'कॉपी करें';
  @override
  String get copied => 'कॉपी किया गया';
  @override
  String get copyAnswerSuccess => 'उत्तर क्लिपबोर्ड पर कॉपी हो गया';
  @override
  String get copySuccessSnackbar => 'उत्तर क्लिपबोर्ड पर कॉपी हो गया';
  @override
  String get wasAnswerHelpful => 'क्या यह उत्तर उपयोगी था?';
  @override
  String get feedbackThanks => 'आपकी प्रतिक्रिया के लिए धन्यवाद!';
  @override
  String get thankYouFeedback => 'आपकी प्रतिक्रिया के लिए धन्यवाद!';
  @override
  String get helpful => 'मददगार';
  @override
  String get notHelpful => 'मददगार नहीं';
  @override
  String get citations => 'उद्धरण (Citations)';
  @override
  String get confidence => 'विश्वसनीयता';
  @override
  String get aiDisclaimer => 'एआई ज्ञान आधार  •  एआई-जनित सामग्री, कृपया संचालन से पहले आधिकारिक दस्तावेज़ों से जांचें';
  @override
  String get allDocsScope => 'सभी दस्तावेज़';
  @override
  String get clearScope => 'चयन साफ़ करें';
  @override
  String get scopeAllDocs => 'दायरा: सभी दस्तावेज़ (Global RAG)';
  @override
  String scopeSelectedDocs(int count) => 'दायरा: $count दस्तावेज़ चयनित';
  @override
  String docProcessingWarning(String title) => 'दस्तावेज़ "$title" अभी संसाधित हो रहा है और प्रश्नों के लिए उपलब्ध नहीं है।';
  @override
  String get errorLoadingDocVersion => 'दस्तावेज़ संस्करण लोड नहीं हो सका। कृपया पुनः प्रयास करें।';
  @override
  String get sessionExpired => 'सत्र समाप्त हो गया, कृपया पुनः साइन इन करें।';
  @override
  String get queryError => 'क्वेरी पूरी करने में असमर्थ। कृपया बैकएंड/एआई कनेक्शन जांचें।';

  @override
  String get snapHeroTitle => 'दृश्य निदान और एआई प्रश्नोत्तर';
  @override
  String get snapHeroSubtitle => 'तुरंत एसओपी खोजने के लिए मशीन प्लेट, त्रुटियों या आरेखों की फ़ोटो लें या अपलोड करें';
  @override
  String get snapUploadPhoto => 'उपकरण फ़ोटो अपलोड करें';
  @override
  String get snapCapturePhoto => 'फ़ोटो लें / अपलोड करें';
  @override
  String get snapLoading => 'अपलोड और विश्लेषण हो रहा है...';
  @override
  String get snapInputPlaceholder => 'इस उपकरण की फ़ोटो के बारे में पूछें…';
  @override
  String get snapAddPhotoFirst => 'पूछने से पहले कृपया एक छवि जोड़ें…';
  @override
  String get snapMachineCodeHint => 'मशीन कोड (वैकल्पिक — उदा. CNC-01)';
  @override
  String get snapSessionExpired => '⚠️ **सत्र समाप्त हो गया।** छवि विश्लेषण से पहले कृपया पुनः साइन इन करें।';
  @override
  String get snapServiceUnavailable => '⚠️ **छवि विश्लेषण सेवा से कनेक्ट नहीं हो सका।** कृपया बैकएंड जांचें और पुनः प्रयास करें।';
  @override
  String get snapAnalysisFailed => '⚠️ **छवि विश्लेषण विफल रहा।** सर्वर ने अमान्य परिणाम दिया; कृपया पुनः प्रयास करें।';
  @override
  String get snapMockWarning => 'कोई वास्तविक ओसीआर या विनिर्देश नहीं मिले।';
  @override
  String get qrComingSoon => 'क्यूआर स्कैनर जल्द आ रहा है — अभी के लिए मशीन कोड मैन्युअल रूप से दर्ज करें।';
  @override
  String get selectImageBeforeAsking => 'कृपया पूछने से पहले एक छवि चुनें';
  @override
  String get scanQrDesc => 'मशीन की पहचान के लिए क्यूआर कोड स्कैन करें';
  @override
  String get addDevicePhoto => 'उपकरण छवि जोड़ें';
  @override
  String get takePhoto => 'फ़ोटो लें';
  @override
  String get takePhotoDesc => 'उपकरण की फ़ोटो लेने के लिए कैमरा खोलें';
  @override
  String get uploadPhoto => 'फ़ोटो अपलोड करें';
  @override
  String get uploadPhotoDescWeb => 'अपने कंप्यूटर से एक छवि फ़ाइल चुनें';
  @override
  String get uploadPhotoDescMobile => 'अपनी गैलरी से फ़ोटो चुनें';
  @override
  String get scanQrCode => 'मशीन क्यूआर स्कैन करें';
  @override
  String get noSnapPhotos => 'अभी तक कोई उपकरण फ़ोटो नहीं';
  @override
  String get noSnapPhotosDesc => 'फ़ोटो लेने, गैलरी से अपलोड करने या क्यूआर स्कैन करने के लिए नीचे दिए गए + बटन पर टैप करें।';
  @override
  String get selectImageToAsk => 'प्रश्न पूछने के लिए एक छवि चुनें';
  @override
  String get noQuestionsYet => 'इस छवि के लिए अभी कोई प्रश्न नहीं';
  @override
  String get typeQuestionBelow => 'विश्लेषण शुरू करने के लिए नीचे अपना प्रश्न लिखें';
  @override
  String get machineCodeHint => 'मशीन कोड (वैकल्पिक — उदा. CNC-01)';
  @override
  String get snapTooltip => 'छवि जोड़ें या क्यूआर स्कैन करें';
  @override
  String get askAboutDevicePhoto => 'इस उपकरण फ़ोटो के बारे में पूछें…';
  @override
  String get addImageFirstToAsk => 'पूछना शुरू करने के लिए पहले एक छवि जोड़ें…';

  @override
  String get documentsTitle => 'औद्योगिक दस्तावेज़ प्रबंधन';
  @override
  String get documentsSubtitle => 'ओसीआर और संस्करण ट्रैकिंग के साथ एसओपी, ब्लूप्रिंट, तकनीकी निर्देश';
  @override
  String get uploadNewDocument => 'नया दस्तावेज़ अपलोड करें';
  @override
  String get uploadDocDesc => 'DCID में एसओपी, तकनीकी आरेख या नियमावली जोड़ें';
  @override
  String get searchDocsPlaceholder => 'शीर्षक, मशीन कोड, श्रेणी के आधार पर खोजें…';
  @override
  String get sortBy => 'इसके अनुसार क्रमबद्ध करें';
  @override
  String get sortNewest => 'नवीनतम पहले';
  @override
  String get sortOldest => 'पुरातन पहले';
  @override
  String get sortTitleAZ => 'शीर्षक A→Z';
  @override
  String get sortTitleZA => 'शीर्षक Z→A';
  @override
  String get sortCategory => 'श्रेणी / मशीन कोड';
  @override
  String get allCategories => 'सभी श्रेणियां';
  @override
  String get allRoles => 'सभी भूमिकाएं';
  @override
  String get docTableTitle => 'दस्तावेज़ शीर्षक';
  @override
  String get docTableCategory => 'श्रेणी';
  @override
  String get docTableMachineCode => 'मशीन कोड';
  @override
  String get docTableMinRole => 'न्यूनतम भूमिका';
  @override
  String get docTableUpdated => 'अंतिम अपडेट';
  @override
  String get docTableActions => 'क्रियाएं';
  @override
  String get docTableVersions => 'संस्करण';
  @override
  String get noDocsFound => 'कोई दस्तावेज़ नहीं मिला';
  @override
  String get noDocsFoundDesc => 'अपनी खोज या फ़िल्टर समायोजित करने का प्रयास करें।';
  @override
  String get uploadSuccessSnackbar => 'अपलोड हो गया — ओसीआर प्रसंस्करण शुरू...';
  @override
  String get fileRequired => 'कृपया एक पीडीएफ दस्तावेज़ फ़ाइल चुनें';
  @override
  String get titleRequired => 'दस्तावेज़ का शीर्षक आवश्यक है';
  @override
  String get categoryRequired => 'श्रेणी आवश्यक है';
  @override
  String get selectPdfFile => 'पीडीएफ दस्तावेज़ चुनें';
  @override
  String get changeFile => 'फ़ाइल बदलें';
  @override
  String get uploading => 'अपलोड हो रहा है...';
  @override
  String get submitUpload => 'अपलोड करें और ओसीआर संसाधित करें';

  @override
  String get documentDetail => 'दस्तावेज़ विवरण';
  @override
  String get deleteDocument => 'दस्तावेज़ हटाएं';
  @override
  String get confirmDelete => 'दस्तावेज़ हटाने की पुष्टि करें';
  @override
  String deleteConfirmDesc(String title) => 'क्या आप वाकई "$title" को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';
  @override
  String get deleteSuccess => 'दस्तावेज़ सफलतापूर्वक हटा दिया गया।';
  @override
  String deleteFailed(String err) => 'दस्तावेज़ हटाने में विफल: $err';
  @override
  String get loadDetailFailed => 'दस्तावेज़ विवरण लोड करने में विफल।';
  @override
  String get versionsList => 'संस्करण सूची';
  @override
  String get noVersions => 'कोई संस्करण उपलब्ध नहीं है।';
  @override
  String versionNumber(int v) => 'संस्करण $v';
  @override
  String get viewOriginalPdf => 'मूल पीडीएफ देखें';
  @override
  String get viewOcrText => 'ओसीआर टेक्स्ट देखें';
  @override
  String get loadingPdf => 'पीडीएफ डाउनलोड हो रही है...';
  @override
  String get invalidBinaryData => 'अमान्य बाइनरी डेटा प्राप्त हुआ';
  @override
  String downloadPdfFailed(String err) => 'पीडीएफ फ़ाइल लोड नहीं हो सकी: $err';
  @override
  String ocrDialogTitle(String name) => 'ओसीआर टेक्स्ट ($name)';
  @override
  String get loadingOcrData => 'ओसीआर डेटा लोड हो रहा है...';
  @override
  String loadOcrFailed(String err) => 'ओसीआर डेटा लोड करने में विफल:\n$err';
  @override
  String get noOcrData => 'इस संस्करण के लिए कोई ओसीआर डेटा नहीं मिला।';
  @override
  String get searchOcrKeyword => 'ओसीआर सामग्री में कीवर्ड खोजें...';
  @override
  String get noOcrPagesMatch => 'आपके खोज कीवर्ड से कोई पृष्ठ मेल नहीं खाता।';
  @override
  String copyPage(int page) => 'पृष्ठ $page कॉपी करें';
  @override
  String pageCopied(int page) => 'पृष्ठ $page कॉपी हो गया';
  @override
  String get blankPageNotice => '(खाली पृष्ठ / कोई टेक्स्ट नहीं)';
  @override
  String get copyAllOcr => 'सभी कॉपी करें';
  @override
  String get allOcrCopied => 'सभी ओसीआर टेक्स्ट क्लिपबोर्ड पर कॉपी हो गए';
  @override
  String pageNumber(int page) => 'पृष्ठ $page';
  @override
  String get machineCode => 'मशीन कोड';
  @override
  String get category => 'श्रेणी';
  @override
  String get minRole => 'न्यूनतम भूमिका';
  @override
  String get description => 'विवरण';
  @override
  String get createdAt => 'बनाया गया';
  @override
  String get updatedAt => 'अपडेट किया गया';

  @override
  String get profileTitle => 'उपयोगकर्ता प्रोफ़ाइल';
  @override
  String get usernameLabel => 'उपयोगकर्ता नाम';
  @override
  String get fullNameLabel => 'पूरा नाम';
  @override
  String get emailLabel => 'ईमेल';
  @override
  String get roleLabel => 'भूमिका';
  @override
  String get changePassword => 'पासवर्ड बदलें';
  @override
  String get currentPassword => 'वर्तमान पासवर्ड';
  @override
  String get newPassword => 'नया पासवर्ड';
  @override
  String get confirmNewPassword => 'नए पासवर्ड की पुष्टि करें';
  @override
  String get currentPasswordRequired => 'कृपया वर्तमान पासवर्ड दर्ज करें';
  @override
  String get newPasswordMinLength => 'नया पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';
  @override
  String get passwordsDoNotMatch => 'पुष्टि पासवर्ड मेल नहीं खाता';
  @override
  String get changePasswordSuccess => 'पासवर्ड सफलतापूर्वक बदल दिया गया।';
  @override
  String get changePasswordError => 'पासवर्ड बदलने में विफल';
  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get historyTitle => 'प्रश्नोत्तरी इतिहास';
  @override
  String get refresh => 'ताज़ा करें';
  @override
  String get noHistoryTitle => 'अभी तक कोई प्रश्न नहीं';
  @override
  String get noHistorySubtitle => 'एआई सहायक से आपके द्वारा पूछे गए प्रश्न यहां दिखाई देंगे।';
  @override
  String get feedbackRecordedHelpful => '👍 आपकी प्रतिक्रिया के लिए धन्यवाद!';
  @override
  String get feedbackRecordedUnhelpful => '👎 प्रतिक्रिया दर्ज की गई।';
  @override
  String get feedbackFailed => 'प्रतिक्रिया भेजने में विफल। बाद में पुनः प्रयास करें।';
  @override
  String get photoSource => 'फ़ोटो स्रोत';
  @override
  String get searchHistoryPlaceholder => 'प्रश्न या उत्तर सामग्री खोजें...';
  @override
  String get filterAllDates => 'सभी समय';
  @override
  String get filterToday => 'आज';
  @override
  String get filter7Days => 'पिछले 7 दिन';
  @override
  String get filter30Days => 'पिछले 30 दिन';
  @override
  String get filterCustomDate => 'कस्टम तिथि...';
  @override
  String get filterAllFeedback => 'सभी प्रतिक्रियाएं';
  @override
  String get filterHelpful => '👍 उपयोगी';
  @override
  String get filterNotHelpful => '👎 उपयोगी नहीं';
  @override
  String get filterUnrated => '⏳ मूल्यांकित नहीं';
  @override
  String get filterLocked => '🔒 सुरक्षित/अवरुद्ध';
  @override
  String get clearFilters => 'फ़िल्टर साफ़ करें';
  @override
  String get noMatchingHistory => 'कोई मेल खाने वाला इतिहास नहीं मिला';
  @override
  String get noMatchingHistoryDesc => 'खोज शब्द या फ़िल्टर समायोजित करने का प्रयास करें।';
  @override
  String get copyQuestionSuccess => 'प्रश्न क्लिपबोर्ड पर कॉपी हो गया!';
  @override
  String showingHistoryCount(int current, int total) => '$total में से $current प्रश्न प्रदर्शित';
  @override
  String get showMore => 'और देखें';
  @override
  String get showLess => 'संक्षिप्त करें';
  @override
  String get feedbackNotePrompt => 'कारण या अतिरिक्त नोट:';

  @override
  String get adminManagement => 'सिस्टम प्रशासन';
  @override
  String get adminSubtitle => 'उपयोगकर्ता खाते, भूमिका असाइनमेंट और एक्सेस नियंत्रण';
  @override
  String get adminUserManagement => 'उपयोगकर्ता प्रबंधन';
  @override
  String get adminAnalytics => 'सिस्टम एनालिटिक्स और केपीआई';
  @override
  String get feedbackTab => 'उपयोगकर्ता प्रतिक्रिया';
  @override
  String get adminFeedbacksTitle => 'एआई उत्तरों पर प्रतिक्रिया लॉग';
  @override
  String get noFeedbacksFound => 'कोई उपयोगकर्ता प्रतिक्रिया नहीं मिली';
  @override
  String get feedbackRating => 'रेटिंग';
  @override
  String get feedbackNoteLabel => 'प्रतिक्रिया विवरण';
  @override
  String get feedbackUserLabel => 'उपयोगकर्ता';
  @override
  String get totalFeedbacks => 'कुल प्रतिक्रियाएं';
  @override
  String get helpfulCountLabel => 'उपयोगी (👍)';
  @override
  String get notHelpfulCountLabel => 'अनुपयोगी (👎)';
  @override
  String get satisfactionRate => 'संतुष्टि दर';
  @override
  String get searchFeedbackPlaceholder => 'प्रश्न, उत्तर, उपयोगकर्ता या नोट द्वारा खोजें...';
  @override
  String get filterAllRatings => 'सभी रेटिंग';
  @override
  String get filterHelpfulOnly => '👍 केवल उपयोगी';
  @override
  String get filterNotHelpfulOnly => '👎 केवल अनुपयोगी';
  @override
  String get columnTime => 'समय';
  @override
  String get columnUser => 'उपयोगकर्ता';
  @override
  String get columnRating => 'रेटिंग';
  @override
  String get columnQuestion => 'प्रश्न';
  @override
  String get columnFeedbackNote => 'प्रतिक्रिया नोट';
  @override
  String get columnConfidence => 'विश्वसनीयता';
  @override
  String showingFeedbacksCount(int count) => '$count प्रतिक्रियाएं प्रदर्शित (विवरण देखने के लिए किसी भी पंक्ति पर क्लिक करें)';
  @override
  String get questionDetailLabel => 'प्रश्न:';
  @override
  String get answerDetailLabel => 'AI उत्तर:';
  @override
  String get dateRange => 'तिथि सीमा';
  @override
  String get createUser => 'उपयोगकर्ता बनाएं';
  @override
  String get createUserTitle => 'नया उपयोगकर्ता खाता बनाएं';
  @override
  String get createUserDialogTitle => 'नया उपयोगकर्ता खाता बनाएं';
  @override
  String get analyticsTab => 'एनालिटिक्स और केपीआई';
  @override
  String get usersTab => 'उपयोगकर्ता खाते';
  @override
  String get searchUsersPlaceholder => 'नाम, उपयोगकर्ता नाम, ईमेल द्वारा खोजें…';
  @override
  String get totalUsers => 'कुल उपयोगकर्ता';
  @override
  String get activeUsers => 'सक्रिय';
  @override
  String get userCreatedSuccess => 'उपयोगकर्ता सफलतापूर्वक बनाया गया';
  @override
  String get analyticsHeadline => 'सिस्टम एनालिटिक्स और केपीआई';
  @override
  String get analyticsSubtitle => 'रीयल-टाइम मेट्रिक्स, गार्डरेल्स अनुपालन और क्वेरी प्रदर्शन।';
  @override
  String get queriesTotal => 'कुल प्रश्न';
  @override
  String get totalQueriesTitle => 'कुल प्रश्न';
  @override
  String get avgConfidence => 'औसत विश्वसनीयता';
  @override
  String get avgConfidenceTitle => 'औसत विश्वसनीयता';
  @override
  String get avgLatencyTitle => 'औसत विलंबता';
  @override
  String get guardrailLockedTitle => 'गार्डरेल लॉक';
  @override
  String get guardrailInterventions => 'गार्डरेल हस्तक्षेप';
  @override
  String get activeSessions => 'सक्रिय सत्र';

  @override
  String get forbiddenTitle => 'पहुंच प्रतिबंधित';
  @override
  String get forbiddenDesc => 'आपको इस अनुभाग को देखने की अनुमति नहीं है।';
  @override
  String get backToSearch => 'DocuMind पर वापस जाएं';
  @override
  String get cancel => 'रद्द करें';
  @override
  String get clear => 'साफ़ करें';
  @override
  String get delete => 'हटाएं';
  @override
  String get close => 'बंद करें';
  @override
  String get retry => 'पुनः प्रयास करें';
  @override
  String get error => 'त्रुटि';
  @override
  String get loading => 'लोड हो रहा है...';
  @override
  String get unknown => 'अज्ञात';
}

// ─────────────────────────────────────────────────────────────────────────────
// Japanese (日本語)
// ─────────────────────────────────────────────────────────────────────────────

class AppStringsJa implements AppStrings {
  const AppStringsJa();

  @override
  String get appTitle => 'DCID';
  @override
  String get appSubtitle => 'Docs';
  @override
  String get appFullName => 'DCID デジタル認識産業システム';
  @override
  String get appTagline => '産業用AIナレッジベース';

  @override
  String get loginHeadline => '技術文書とAIアシスタントにアクセスするにはログインしてください';
  @override
  String get username => 'ユーザー名';
  @override
  String get password => 'パスワード';
  @override
  String get signIn => 'ログイン';
  @override
  String get authFailed => '認証に失敗しました';
  @override
  String get usernameRequired => 'ユーザー名を入力してください';
  @override
  String get passwordRequired => 'パスワードを入力してください';

  @override
  String get navDocuMind => 'DocuMind';
  @override
  String get navSnapAsk => 'Snap & Ask';
  @override
  String get navDocuments => '文書管理';
  @override
  String get navAdmin => 'システム管理';
  @override
  String get newChat => '新規チャット';
  @override
  String get recents => '最近の履歴';
  @override
  String get profileTooltip => 'ユーザープロファイル';
  @override
  String get profileMenuTooltip => 'プロファイル設定・パスワード変更';
  @override
  String get historyTooltip => '質問履歴';
  @override
  String get logoutTooltip => 'ログアウト';
  @override
  String get expandSidebar => 'サイドバーを展開';
  @override
  String get collapseSidebar => 'サイドバーを折りたたむ';
  @override
  String get switchToLight => 'ライトモードに切り替え';
  @override
  String get switchToDark => 'ダークモードに切り替え';
  @override
  String get switchLanguage => '言語の切り替え';
  @override
  String get currentLanguage => '言語: 日本語';

  @override
  String get roleOperator => 'オペレーター (Operator)';
  @override
  String get roleEngineer => 'エンジニア (Engineer)';
  @override
  String get roleQaAdmin => 'QA / 管理者 (QA / Admin)';
  @override
  String get roleAdmin => 'システム管理者 (Admin)';

  @override
  String get searchHeroTitle => 'DCID Docs';
  @override
  String get searchHeroSubtitle => 'AI搭載 産業用技術文書・ナレッジアシスタント';
  @override
  String get searchPlaceholderAll => 'SOP、仕様書、図面について質問する（全文書対象）…';
  @override
  String searchPlaceholderSelected(int count) => '選択中の $count 件の文書から質問…';
  @override
  String get insufficientConfidenceBanner => '⚠ データの信頼度が不十分です。\n回答は低い信頼度で生成されました。作業前に公式文書と照合して確認してください。';
  @override
  String get lockedAnswerWarning => '⚠ データの信頼度が不十分です。信頼度が低いため回答がロックされています。公式文書をご確認ください。';
  @override
  String get directDataExtraction => '直接データ抽出';
  @override
  String get reasoningMode => '詳細推論モード';
  @override
  String get referenceSources => '参照ソース';
  @override
  String get copy => 'コピー';
  @override
  String get copied => 'コピー完了';
  @override
  String get copyAnswerSuccess => '回答内容をクリップボードにコピーしました';
  @override
  String get copySuccessSnackbar => '回答内容をクリップボードにコピーしました';
  @override
  String get wasAnswerHelpful => 'この回答は役に立ちましたか？';
  @override
  String get feedbackThanks => 'フィードバックありがとうございます！';
  @override
  String get thankYouFeedback => 'フィードバックありがとうございます！';
  @override
  String get helpful => '役に立った';
  @override
  String get notHelpful => '不正確';
  @override
  String get citations => '引用文献 (Citations)';
  @override
  String get confidence => '信頼度';
  @override
  String get aiDisclaimer => 'AIナレッジベース  •  AI生成コンテンツです。操作前に必ず公式文書で確認してください';
  @override
  String get allDocsScope => 'すべての文書';
  @override
  String get clearScope => '選択解除';
  @override
  String get scopeAllDocs => 'スコープ: すべての文書 (Global RAG)';
  @override
  String scopeSelectedDocs(int count) => 'スコープ: $count 件の文書を選択中';
  @override
  String docProcessingWarning(String title) => '文書「$title」は現在処理中のため、AI検索にはまだ使用できません。';
  @override
  String get errorLoadingDocVersion => '文書のバージョンを読み込めませんでした。再試行してください。';
  @override
  String get sessionExpired => 'セッションの有効期限が切れました。再度ログインしてください。';
  @override
  String get queryError => 'クエリを完了できませんでした。バックエンド・AIの接続を確認してください。';

  @override
  String get snapHeroTitle => '画像診断・AI Q&A';
  @override
  String get snapHeroSubtitle => '機械銘板やエラー画面、図面の写真を撮影・アップロードして即座にSOPを検索';
  @override
  String get snapUploadPhoto => '機器写真をアップロード';
  @override
  String get snapCapturePhoto => '写真を撮影 / アップロード';
  @override
  String get snapLoading => 'アップロード・分析中...';
  @override
  String get snapInputPlaceholder => 'この機器の写真について質問する…';
  @override
  String get snapAddPhotoFirst => '質問する前に機器の画像を追加してください…';
  @override
  String get snapMachineCodeHint => '機械コード（任意 — 例: CNC-01）';
  @override
  String get snapSessionExpired => '⚠️ **セッションが切れました。** 画像分析を行う前に再度ログインしてください。';
  @override
  String get snapServiceUnavailable => '⚠️ **画像分析サービスに接続できません。** バックエンドとAIサービスを確認して再試行してください。';
  @override
  String get snapAnalysisFailed => '⚠️ **画像分析に失敗しました。** サーバーから有効な応答がありませんでした。';
  @override
  String get snapMockWarning => 'OCRデータまたは仕様情報が見つかりませんでした。';
  @override
  String get qrComingSoon => 'QRスキャナーは近日公開予定です — 機械コードを手動で入力してください。';
  @override
  String get selectImageBeforeAsking => '質問する前に画像を選択または撮影してください';
  @override
  String get scanQrDesc => '機械を識別するためにQRコードをスキャン';
  @override
  String get addDevicePhoto => '機器画像を追加';
  @override
  String get takePhoto => '写真を撮影';
  @override
  String get takePhotoDesc => 'カメラを起動して機器や銘板を撮影';
  @override
  String get uploadPhoto => '写真をアップロード';
  @override
  String get uploadPhotoDescWeb => 'コンピューターから画像ファイルを選択';
  @override
  String get uploadPhotoDescMobile => 'ギャラリーから写真を選択';
  @override
  String get scanQrCode => '機械QRコードをスキャン';
  @override
  String get noSnapPhotos => '機器の写真がまだありません';
  @override
  String get noSnapPhotosDesc => '下の + ボタンをタップして写真を撮影、\nギャラリーからアップロード、またはQRコードをスキャンしてください。';
  @override
  String get selectImageToAsk => '画像を選択して質問を開始してください';
  @override
  String get noQuestionsYet => 'この画像に関する質問はまだありません';
  @override
  String get typeQuestionBelow => '分析を開始するには下に質問を入力してください';
  @override
  String get machineCodeHint => '機械コード（任意 — 例: CNC-01）';
  @override
  String get snapTooltip => '画像を追加またはQRをスキャン';
  @override
  String get askAboutDevicePhoto => 'この機器の写真について質問する…';
  @override
  String get addImageFirstToAsk => '質問を始める前に画像を追加してください…';

  @override
  String get documentsTitle => '技術文書管理';
  @override
  String get documentsSubtitle => 'OCRおよびバージョン追跡対応のSOP、設計図面、エンジニアリング仕様書';
  @override
  String get uploadNewDocument => '新規文書をアップロード';
  @override
  String get uploadDocDesc => 'DCIDにSOP、図面、マニュアル、技術仕様を追加';
  @override
  String get searchDocsPlaceholder => 'タイトル、機械コード、カテゴリで検索…';
  @override
  String get sortBy => '並べ替え';
  @override
  String get sortNewest => '新しい順';
  @override
  String get sortOldest => '古い順';
  @override
  String get sortTitleAZ => 'タイトル昇順 (A→Z)';
  @override
  String get sortTitleZA => 'タイトル降順 (Z→A)';
  @override
  String get sortCategory => 'カテゴリ / 機械コード';
  @override
  String get allCategories => 'すべてのカテゴリ';
  @override
  String get allRoles => 'すべての権限';
  @override
  String get docTableTitle => '文書タイトル';
  @override
  String get docTableCategory => 'カテゴリ';
  @override
  String get docTableMachineCode => '機械コード';
  @override
  String get docTableMinRole => '最小必要権限';
  @override
  String get docTableUpdated => '更新日時';
  @override
  String get docTableActions => '操作';
  @override
  String get docTableVersions => 'バージョン';
  @override
  String get noDocsFound => '文書が見つかりませんでした';
  @override
  String get noDocsFoundDesc => '検索キーワードやカテゴリ・権限フィルターを変更してお試しください。';
  @override
  String get uploadSuccessSnackbar => 'アップロード完了 — OCR処理を開始しました...';
  @override
  String get fileRequired => 'PDF文書ファイルを選択してください';
  @override
  String get titleRequired => '文書タイトルを入力してください';
  @override
  String get categoryRequired => 'カテゴリを選択してください';
  @override
  String get selectPdfFile => 'PDF文書を選択';
  @override
  String get changeFile => 'ファイルを変更';
  @override
  String get uploading => 'アップロード中...';
  @override
  String get submitUpload => 'アップロードしてOCR処理を開始';

  @override
  String get documentDetail => '文書詳細';
  @override
  String get deleteDocument => '文書を削除';
  @override
  String get confirmDelete => '文書削除の確認';
  @override
  String deleteConfirmDesc(String title) => '本当に「$title」を削除しますか？この操作は取り消せません。';
  @override
  String get deleteSuccess => '文書を正常に削除しました。';
  @override
  String deleteFailed(String err) => '文書の削除に失敗しました: $err';
  @override
  String get loadDetailFailed => '文書詳細の読み込みに失敗しました。';
  @override
  String get versionsList => 'バージョン一覧';
  @override
  String get noVersions => 'バージョンがまだありません。';
  @override
  String versionNumber(int v) => 'バージョン $v';
  @override
  String get viewOriginalPdf => '元のPDFを表示';
  @override
  String get viewOcrText => 'OCRテキストを表示';
  @override
  String get loadingPdf => 'PDFファイルをダウンロード中...';
  @override
  String get invalidBinaryData => '受信データが有効なバイナリ形式ではありません';
  @override
  String downloadPdfFailed(String err) => 'PDFファイルの読み込みに失敗しました: $err';
  @override
  String ocrDialogTitle(String name) => 'OCRテキスト ($name)';
  @override
  String get loadingOcrData => 'OCRデータを読み込み中...';
  @override
  String loadOcrFailed(String err) => 'OCRデータの読み込みに失敗しました:\n$err';
  @override
  String get noOcrData => 'このバージョンのOCRデータは見つかりませんでした。';
  @override
  String get searchOcrKeyword => 'OCRテキスト内のキーワードを検索...';
  @override
  String get noOcrPagesMatch => '検索キーワードに一致するページがありません。';
  @override
  String copyPage(int page) => 'ページ $page をコピー';
  @override
  String pageCopied(int page) => 'ページ $page の内容をコピーしました';
  @override
  String get blankPageNotice => '(空白ページ / テキストなし)';
  @override
  String get copyAllOcr => 'すべてコピー';
  @override
  String get allOcrCopied => 'すべてのOCRテキストをクリップボードにコピーしました';
  @override
  String pageNumber(int page) => 'ページ $page';
  @override
  String get machineCode => '機械コード';
  @override
  String get category => 'カテゴリ';
  @override
  String get minRole => '最小必要権限';
  @override
  String get description => '説明';
  @override
  String get createdAt => '作成日時';
  @override
  String get updatedAt => '更新日時';

  @override
  String get profileTitle => 'ユーザープロファイル';
  @override
  String get usernameLabel => 'ユーザー名';
  @override
  String get fullNameLabel => '氏名';
  @override
  String get emailLabel => 'メールアドレス';
  @override
  String get roleLabel => '役割・権限';
  @override
  String get changePassword => 'パスワード変更';
  @override
  String get currentPassword => '現在のパスワード';
  @override
  String get newPassword => '新しいパスワード';
  @override
  String get confirmNewPassword => '新しいパスワード（確認）';
  @override
  String get currentPasswordRequired => '現在のパスワードを入力してください';
  @override
  String get newPasswordMinLength => '新しいパスワードは6文字以上で入力してください';
  @override
  String get passwordsDoNotMatch => '確認用パスワードが一致しません';
  @override
  String get changePasswordSuccess => 'パスワードを正常に変更しました。';
  @override
  String get changePasswordError => 'パスワードの変更に失敗しました';
  @override
  String get saveChanges => '変更を保存';

  @override
  String get historyTitle => '質問履歴';
  @override
  String get refresh => '更新';
  @override
  String get noHistoryTitle => '質問履歴がありません';
  @override
  String get noHistorySubtitle => 'AIアシスタントに質問した履歴がここに表示されます。';
  @override
  String get feedbackRecordedHelpful => '👍 フィードバックありがとうございます！';
  @override
  String get feedbackRecordedUnhelpful => '👎 フィードバックを記録しました。';
  @override
  String get feedbackFailed => 'フィードバックを送信できませんでした。';
  @override
  String get photoSource => '画像ソース';
  @override
  String get searchHistoryPlaceholder => '質問または回答内容を検索...';
  @override
  String get filterAllDates => '全期間';
  @override
  String get filterToday => '今日';
  @override
  String get filter7Days => '過去7日間';
  @override
  String get filter30Days => '過去30日間';
  @override
  String get filterCustomDate => '日付指定...';
  @override
  String get filterAllFeedback => 'すべての評価';
  @override
  String get filterHelpful => '👍 役に立った';
  @override
  String get filterNotHelpful => '👎 役に立たなかった';
  @override
  String get filterUnrated => '⏳ 未評価';
  @override
  String get filterLocked => '🔒 ガード/保護';
  @override
  String get clearFilters => 'フィルター解除';
  @override
  String get noMatchingHistory => '該当する質問履歴がありません';
  @override
  String get noMatchingHistoryDesc => '検索キーワードや日付フィルターを変更してお試しください。';
  @override
  String get copyQuestionSuccess => '質問をクリップボードにコピーしました！';
  @override
  String showingHistoryCount(int current, int total) => '$total 件中 $current 件を表示';
  @override
  String get showMore => 'もっと見る';
  @override
  String get showLess => '折りたたむ';
  @override
  String get feedbackNotePrompt => '理由や追加コメント（任意）:';

  @override
  String get adminManagement => 'システム管理';
  @override
  String get adminSubtitle => 'ユーザーアカウント、役割の割り当て、アクセス権限の管理';
  @override
  String get adminUserManagement => 'ユーザー管理';
  @override
  String get adminAnalytics => 'システム分析 & KPI';
  @override
  String get feedbackTab => 'ユーザー評価一覧';
  @override
  String get adminFeedbacksTitle => 'AI回答へのユーザーフィードバック履歴';
  @override
  String get noFeedbacksFound => 'ユーザーフィードバックはまだありません';
  @override
  String get feedbackRating => '評価';
  @override
  String get feedbackNoteLabel => 'コメント';
  @override
  String get feedbackUserLabel => 'ユーザー';
  @override
  String get totalFeedbacks => '総フィードバック数';
  @override
  String get helpfulCountLabel => '役に立った (👍)';
  @override
  String get notHelpfulCountLabel => '役に立たなかった (👎)';
  @override
  String get satisfactionRate => '満足度';
  @override
  String get searchFeedbackPlaceholder => '質問、回答、ユーザー、メモで検索...';
  @override
  String get filterAllRatings => 'すべての評価';
  @override
  String get filterHelpfulOnly => '👍 役に立ったのみ';
  @override
  String get filterNotHelpfulOnly => '👎 役に立たなかったのみ';
  @override
  String get columnTime => '日時';
  @override
  String get columnUser => 'ユーザー';
  @override
  String get columnRating => '評価';
  @override
  String get columnQuestion => '質問';
  @override
  String get columnFeedbackNote => 'フィードバックメモ';
  @override
  String get columnConfidence => '信頼度';
  @override
  String showingFeedbacksCount(int count) => '$count 件のフィードバックを表示中（行をクリックして詳細を表示）';
  @override
  String get questionDetailLabel => '質問:';
  @override
  String get answerDetailLabel => 'AIの回答:';
  @override
  String get dateRange => '期間';
  @override
  String get createUser => 'ユーザー作成';
  @override
  String get createUserTitle => '新規ユーザーアカウント作成';
  @override
  String get createUserDialogTitle => '新規ユーザーアカウント作成';
  @override
  String get analyticsTab => '分析 & KPI';
  @override
  String get usersTab => 'ユーザーアカウント';
  @override
  String get searchUsersPlaceholder => '名前、ユーザー名、メールで検索…';
  @override
  String get totalUsers => '総ユーザー数';
  @override
  String get activeUsers => 'アクティブ';
  @override
  String get userCreatedSuccess => 'ユーザーが正常に作成されました';
  @override
  String get analyticsHeadline => 'システム分析 & KPI';
  @override
  String get analyticsSubtitle => 'リアルタイム指標、ガードレール遵守状況、クエリパフォーマンス。';
  @override
  String get queriesTotal => '総クエリ数';
  @override
  String get totalQueriesTitle => '総クエリ数';
  @override
  String get avgConfidence => '平均信頼度';
  @override
  String get avgConfidenceTitle => '平均信頼度';
  @override
  String get avgLatencyTitle => '平均レイテンシ';
  @override
  String get guardrailLockedTitle => 'ガードレール遮断 (Guardrail Locked)';
  @override
  String get guardrailInterventions => 'ガードレール介入';
  @override
  String get activeSessions => 'アクティブセッション';

  @override
  String get forbiddenTitle => 'アクセス拒否';
  @override
  String get forbiddenDesc => 'このセクションを閲覧する権限がありません。';
  @override
  String get backToSearch => 'DocuMindに戻る';
  @override
  String get cancel => 'キャンセル';
  @override
  String get clear => 'クリア';
  @override
  String get delete => '削除';
  @override
  String get close => '閉じる';
  @override
  String get retry => '再試行';
  @override
  String get error => 'エラー';
  @override
  String get loading => '読み込み中...';
  @override
  String get unknown => '不明';
}
