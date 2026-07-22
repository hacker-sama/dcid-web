/// Bootstrap hook cho các cấu hình đặc thù nền tảng lúc khởi động app.
///
/// Quyết định kiến trúc: "máy tính" (desktop/admin) chạy dưới dạng **web**
/// (mở trong trình duyệt), không phải app native — nên không còn khái niệm
/// "kiosk mode" ở tầng ứng dụng (fullscreen do trình duyệt/OS đảm nhiệm,
/// vd Chromium `--kiosk` trỏ tới URL, hoặc phím F11).
///
/// Cố tình KHÔNG import `dart:io` ở đây — `dart:io` không biên dịch được cho
/// target web, và mọi platform-check kiểu `Platform.isWindows` sẽ làm vỡ
/// `flutter build web`. Nếu sau này thực sự cần một app desktop native
/// riêng, đặt logic đó sau một `kIsWeb` guard (package:flutter/foundation.dart)
/// hoặc trong một entrypoint build riêng — không import dart:io ở top-level.
Future<void> configureKioskIfDesktop() async {
  // No-op: xem ghi chú kiến trúc ở trên (docs/FRONTEND.md).
}
