#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dcid-app"

command -v flutter >/dev/null 2>&1 || {
  echo "Không tìm thấy Flutter. Cài Flutter rồi thêm flutter/bin vào PATH."
  exit 1
}
command -v xcodebuild >/dev/null 2>&1 || {
  echo "Không tìm thấy Xcode command line tools. Mở Xcode một lần và chạy: xcode-select --install"
  exit 1
}

cd "$APP_DIR"

echo "[1/5] Kiểm tra môi trường Flutter..."
flutter doctor

echo "[2/5] Tạo phần iOS/macOS còn thiếu mà không ghi đè lib/..."
flutter create --platforms=ios,macos --org vn.dcid --project-name dcid_app .

echo "[3/5] Tải package Dart/Flutter..."
flutter pub get

echo "[4/5] Cài CocoaPods cho iOS/macOS nếu có..."
if command -v pod >/dev/null 2>&1; then
  [ -d ios ] && (cd ios && pod install)
  [ -d macos ] && (cd macos && pod install)
else
  echo "CocoaPods chưa có. Nếu build báo lỗi Pods, cài bằng: sudo gem install cocoapods"
fi

echo "[5/5] Mở project macOS trong Xcode..."
if [ -f macos/Runner.xcworkspace ]; then
  open macos/Runner.xcworkspace
else
  open macos/Runner.xcodeproj
fi

echo
printf '%s\n' "Hoàn tất. Trong Xcode chọn scheme Runner > My Mac > nút Run." \
  "Bản này mặc định dùng dữ liệu mẫu nên giao diện chạy được ngay, không cần backend." \
  "Để dùng backend thật, chạy bằng Terminal:" \
  "flutter run -d macos --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080"
