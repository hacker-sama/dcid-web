#!/usr/bin/env bash
# Root-owned helper installed by setup-ci-user.sh.
# It intentionally accepts no arguments so CI can only deploy DCID's Nginx file.
set -euo pipefail

SOURCE_CONFIG="/opt/dcid/nginx/dcid.conf"
TARGET_CONFIG="/etc/nginx/sites-available/dcid.conf"
ENABLED_CONFIG="/etc/nginx/sites-enabled/dcid.conf"

if [ ! -f "$SOURCE_CONFIG" ]; then
  echo "Missing Nginx source config: $SOURCE_CONFIG" >&2
  exit 1
fi

backup_file="$(mktemp)"
target_existed=false
enabled_existed=false

cleanup() {
  rm -f "$backup_file"
}
trap cleanup EXIT

if [ -e "$TARGET_CONFIG" ] || [ -L "$TARGET_CONFIG" ]; then
  cp -a "$TARGET_CONFIG" "$backup_file"
  target_existed=true
fi

if [ -e "$ENABLED_CONFIG" ] || [ -L "$ENABLED_CONFIG" ]; then
  enabled_existed=true
fi

install -m 0644 "$SOURCE_CONFIG" "$TARGET_CONFIG"
if [ -d /etc/nginx/sites-enabled ]; then
  ln -sfn "$TARGET_CONFIG" "$ENABLED_CONFIG"
fi

if ! nginx -t; then
  echo "Invalid Nginx config; restoring the previous file." >&2
  if [ "$target_existed" = true ]; then
    install -m 0644 "$backup_file" "$TARGET_CONFIG"
  else
    rm -f "$TARGET_CONFIG"
  fi
  if [ "$enabled_existed" = false ]; then
    rm -f "$ENABLED_CONFIG"
  fi
  nginx -t || true
  exit 1
fi

systemctl reload nginx
echo "Nginx configuration deployed and reloaded."
