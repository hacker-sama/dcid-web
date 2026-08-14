#!/usr/bin/env bash
# =============================================================================
# scripts/setup-ci-user.sh — Tạo tài khoản CI deploy trên VPS
#
# Chạy 1 lần duy nhất bởi người đang có quyền sudo:
#   sudo bash scripts/setup-ci-user.sh
#
# Script này tạo user "ci-deploy" chuyên dùng cho GitHub Actions:
#   - SSH key riêng (không dùng key cá nhân)
#   - Thuộc nhóm docker (cần để chạy docker compose)
#   - KHÔNG có password login
#   - KHÔNG có sudo (chỉ cần docker + đọc/ghi /opt/dcid và /var/www/dcid-web)
# =============================================================================
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
  echo "Cần chạy bằng sudo: sudo bash scripts/setup-ci-user.sh"
  exit 1
fi

CI_USER="ci-deploy"
PROJECT_DIR="/opt/dcid"
WEB_DIR="/var/www/dcid-web"

echo "=== Tạo user $CI_USER ==="
if ! id "$CI_USER" > /dev/null 2>&1; then
  adduser --disabled-password --gecos "DCID CI Deploy" "$CI_USER"
  echo "  ✅ User $CI_USER đã được tạo"
else
  echo "  ℹ️  User $CI_USER đã tồn tại — bỏ qua bước tạo"
fi

echo "=== Thêm vào nhóm docker ==="
usermod -aG docker "$CI_USER"
echo "  ✅ $CI_USER thuộc nhóm docker"

echo "=== Cấp quyền đọc/ghi thư mục project ==="
# CI user cần pull git, docker compose, và rsync flutter build
chown -R "$CI_USER:$CI_USER" "$PROJECT_DIR" 2>/dev/null || true
chmod -R g+rw "$PROJECT_DIR" 2>/dev/null || true

# Cấp quyền deploy Flutter build
mkdir -p "$WEB_DIR"
chown -R "$CI_USER:$CI_USER" "$WEB_DIR"
echo "  ✅ Quyền $PROJECT_DIR và $WEB_DIR đã set"

echo "=== Thiết lập SSH authorized_keys ==="
CI_HOME="$(getent passwd "$CI_USER" | cut -d: -f6)"
install -d -m 700 -o "$CI_USER" -g "$CI_USER" "$CI_HOME/.ssh"
touch "$CI_HOME/.ssh/authorized_keys"
chmod 600 "$CI_HOME/.ssh/authorized_keys"
chown "$CI_USER:$CI_USER" "$CI_HOME/.ssh/authorized_keys"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Bước tiếp theo — Tạo SSH key riêng cho CI:"
echo ""
echo "  # Trên máy local (KHÔNG phải VPS):"
echo "  ssh-keygen -t ed25519 -C \"dcid-ci-deploy\" -f ~/.ssh/dcid_ci_deploy"
echo "  cat ~/.ssh/dcid_ci_deploy.pub"
echo ""
echo "  # Dán public key vào:"
echo "  sudo -u $CI_USER sh -c 'echo \"<PUBLIC_KEY>\" >> $CI_HOME/.ssh/authorized_keys'"
echo ""
echo "  # Copy private key vào GitHub:"
echo "  # Settings → Secrets → Actions → New secret:"
echo "  #   VPS_SSH_KEY  = nội dung file ~/.ssh/dcid_ci_deploy (private key)"
echo "  #   VPS_HOST     = 160.250.132.20"
echo "  #   VPS_USER     = ci-deploy"
echo "  #   VPS_PORT     = 22"
echo "  #   API_BASE_URL = https://160.250.132.20.sslip.io"
echo ""
echo "  # Test kết nối:"
echo "  ssh -i ~/.ssh/dcid_ci_deploy ci-deploy@160.250.132.20 'docker ps --filter name=dcid-'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
