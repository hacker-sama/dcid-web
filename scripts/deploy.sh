#!/bin/bash
# =============================================================================
# scripts/deploy.sh — Deploy thủ công trên VPS bởi nhóm trưởng
#
# Dùng khi:
#   - Cần deploy hotfix ngoài pipeline GitHub Actions
#   - Debug / rollback thủ công
#   - Test cấu hình mới trước khi commit
#
# Cách dùng: cd /opt/dcid && bash scripts/deploy.sh [OPTION]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"   # /opt/dcid
cd "$PROJECT_DIR"

# ── Kiểm tra .env.production tồn tại ─────────────────────────────────────────
if [ ! -f .env.production ]; then
  echo "❌ Không tìm thấy .env.production"
  echo "   Tạo file này từ .env.example và điền giá trị thật."
  exit 1
fi

# ── Lệnh compose chuẩn (docker compose v2, đủ 3 overlay) ────────────────────
COMPOSE="docker compose \
  --env-file .env.production \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  -f docker-compose.vps.yml"

# ── Hàm health check với retry ───────────────────────────────────────────────
health_check() {
  local max_retries=8
  for i in $(seq 1 $max_retries); do
    echo "  Health check $i/$max_retries..."
    if curl -sf http://127.0.0.1:8080/api/health > /dev/null 2>&1; then
      echo "  ✅ Backend healthy"
      return 0
    fi
    sleep 10
  done
  echo "  ❌ Backend không phản hồi sau ${max_retries} lần thử"
  return 1
}

case "${1:-}" in

  # ── Full deploy: pull → build → up ────────────────────────────────────────
  --full)
    PREV_COMMIT=$(git rev-parse HEAD)
    echo "=== Full deploy ==="
    echo "  Từ commit: $PREV_COMMIT"
    git pull --ff-only origin main
    echo "  Đến commit: $(git rev-parse HEAD)"

    $COMPOSE build backend ai ai-worker ai-ocr
    $COMPOSE up -d

    if health_check; then
      echo "✅ Deploy hoàn tất — $(git rev-parse --short HEAD)"
    else
      echo "❌ Thất bại — rollback về $PREV_COMMIT"
      git checkout "$PREV_COMMIT"
      $COMPOSE build backend ai ai-worker ai-ocr
      $COMPOSE up -d
      echo "🔁 Đã rollback. Kiểm tra logs: bash scripts/deploy.sh --logs"
      exit 1
    fi
    ;;

  # ── Chỉ pull code (không build, không restart) ────────────────────────────
  --pull)
    echo "=== Git pull ==="
    git pull --ff-only origin main
    echo "  HEAD: $(git rev-parse --short HEAD)"
    ;;

  # ── Chỉ build images ──────────────────────────────────────────────────────
  --build)
    echo "=== Build images ==="
    $COMPOSE build backend ai ai-worker ai-ocr
    ;;

  # ── Chỉ restart containers (dùng image đang có) ───────────────────────────
  --restart)
    echo "=== Restart containers ==="
    $COMPOSE up -d
    health_check
    ;;

  # ── Rollback về commit trước ──────────────────────────────────────────────
  --rollback)
    TARGET="${2:-HEAD~1}"
    echo "=== Rollback về $TARGET ==="
    git checkout "$TARGET"
    $COMPOSE build backend ai ai-worker ai-ocr
    $COMPOSE up -d
    health_check
    ;;

  # ── Xem trạng thái ────────────────────────────────────────────────────────
  --status)
    echo "=== Container status ==="
    docker ps --filter "name=dcid-" \
      --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "=== Số container đang chạy ==="
    docker ps --filter "name=dcid-" -q | wc -l
    echo ""
    echo "=== Health API ==="
    curl -sf http://127.0.0.1:8080/api/health && echo " ✅" || echo " ❌ (backend chưa sẵn sàng)"
    echo ""
    echo "=== Commit hiện tại ==="
    git log --oneline -3
    ;;

  # ── Theo dõi log realtime ─────────────────────────────────────────────────
  --logs)
    $COMPOSE logs -f --tail=100 backend ai ai-worker ai-ocr
    ;;

  # ── Validate cấu hình compose (không khởi động gì) ───────────────────────
  --validate)
    echo "=== Validate compose config ==="
    $COMPOSE config --quiet && echo "✅ Config hợp lệ"
    ;;

  *)
    cat <<EOF
Cách dùng: bash scripts/deploy.sh [OPTION]

  --full          Pull code mới, build images, restart, health check + auto rollback
  --pull          Chỉ git pull (không build/restart)
  --build         Chỉ build lại images
  --restart       Chỉ restart containers (không build/pull)
  --rollback [REF] Rollback về commit/tag cụ thể (mặc định: HEAD~1)
  --status        Hiện trạng container, health, git log
  --logs          Xem logs realtime (Ctrl+C để thoát)
  --validate      Kiểm tra compose config không lỗi

Ví dụ:
  bash scripts/deploy.sh --full
  bash scripts/deploy.sh --rollback v1.2.3
  bash scripts/deploy.sh --status
EOF
    exit 1
    ;;
esac
