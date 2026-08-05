# Chạy DCID bằng Xcode trên MacBook

## Dự án này là gì?

Phần giao diện là Flutter trong `dcid-app`. File gốc chưa chứa `ios/` và `macos/`, nên Xcode không thể mở ngay. Script đi kèm sẽ dùng Flutter để sinh hai platform này, giữ nguyên mã Dart hiện có, cài dependencies và mở workspace Xcode.

Backend Spring Boot, AI FastAPI và Docker không chạy *bên trong* Xcode. Xcode chỉ build/run ứng dụng Flutter cho iOS hoặc macOS.

## Cách nhanh nhất

1. Giải nén dự án.
2. Mở Terminal tại thư mục `dcid-web`.
3. Chạy:

```bash
chmod +x scripts/setup_xcode_mac.sh
./scripts/setup_xcode_mac.sh
```

Hoặc nhấp đúp `scripts/run_xcode_mac.command` trong Finder.

Script sẽ:

- kiểm tra Flutter/Xcode;
- tạo `dcid-app/ios` và `dcid-app/macos`;
- chạy `flutter pub get`;
- chạy CocoaPods nếu đã cài;
- mở `dcid-app/macos/Runner.xcworkspace` trong Xcode.

## Chạy trong Xcode

### macOS

- Scheme: `Runner`
- Destination: `My Mac`
- Bấm nút ▶ Run.

### iPhone Simulator

```bash
cd dcid-app
open ios/Runner.xcworkspace
```

Trong Xcode chọn một iPhone Simulator rồi bấm ▶ Run.

## Chế độ chạy ngay không cần backend

`lib/main.dart` đã được chỉnh để mặc định:

```dart
USE_MOCK_DATA=true
```

Vì vậy khi bấm Run trực tiếp trong Xcode, ứng dụng dùng dữ liệu mẫu và có thể mở giao diện ngay.

Tài khoản mock:

- Username: `admin`
- Password: nhập bất kỳ chuỗi không rỗng nếu màn mock yêu cầu.

## Dùng backend thật

Khởi động hạ tầng và backend ở Terminal riêng:

```bash
cd dcid-web
docker compose up -d postgres minio chroma redis

cd dcid-backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

Sau đó chạy ứng dụng bằng Flutter CLI, vẫn sử dụng toolchain Xcode:

```bash
cd dcid-app
flutter run -d macos \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=http://localhost:8080
```

Với iOS Simulator, `localhost` trỏ về máy Mac và thường dùng được:

```bash
flutter run -d ios \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=http://localhost:8080
```

Với iPhone thật, thay `localhost` bằng IP LAN của Mac, ví dụ `http://192.168.1.10:8080`.

## Lỗi thường gặp

### `flutter: command not found`

Cài Flutter SDK và thêm `flutter/bin` vào PATH.

### CocoaPods chưa có

```bash
sudo gem install cocoapods
pod setup
```

### Xcode chưa chấp nhận license

```bash
sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### macOS chặn kết nối HTTP localhost

Flutter-generated macOS project thường cho phép kết nối debug. Nếu bản release chặn HTTP, cấu hình App Transport Security hoặc dùng HTTPS.
