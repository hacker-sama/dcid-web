#!/bin/bash
# Daily backup script — thêm vào crontab: 0 2 * * * /opt/dcid/scripts/backup.sh
set -e
BACKUP_DIR="/opt/dcid/backups"
DATE=$(date +%Y%m%d_%H%M)
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting backup..."

# PostgreSQL dump
docker exec dcid-postgres pg_dump -U dcid dcid \
  | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"

# Giữ 7 bản gần nhất
ls -t "$BACKUP_DIR"/postgres_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm -f

echo "[$(date)] Backup completed: postgres_$DATE.sql.gz"

# List current backups
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "No backups found"
