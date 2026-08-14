#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-dcid-postgres}"

if ! docker inspect "$POSTGRES_CONTAINER" >/dev/null 2>&1; then
    echo "Khong tim thay container $POSTGRES_CONTAINER. Hay khoi dong Docker Compose truoc."
    exit 1
fi

if [ "$(docker inspect -f '{{.State.Running}}' "$POSTGRES_CONTAINER")" != "true" ]; then
    echo "Container $POSTGRES_CONTAINER chua chay."
    exit 1
fi

echo "Khoi tao/cap nhat cac nhom quyen PostgreSQL..."
docker exec -i "$POSTGRES_CONTAINER" \
    psql -v ON_ERROR_STOP=1 -U dcid -d dcid \
    < "$SCRIPT_DIR/postgres-team-roles.sql"

read -r -p "Username PostgreSQL cua thanh vien: " MEMBER_NAME
if [[ ! "$MEMBER_NAME" =~ ^[a-z][a-z0-9_]{2,31}$ ]]; then
    echo "Username phai gom 3-32 ky tu: chu thuong, so, dau gach duoi; bat dau bang chu."
    exit 1
fi

case "$MEMBER_NAME" in
    dcid|postgres|dcid_readonly|dcid_editor|dcid_maintainer)
        echo "Username nay duoc danh rieng cho he thong. Hay chon ten khac."
        exit 1
        ;;
esac

echo "Chon quyen:"
echo "  1) readonly   - chi xem du lieu"
echo "  2) editor     - xem/them/sua/xoa du lieu"
echo "  3) maintainer - bao tri database (danh cho nhom truong)"
read -r -p "Lua chon [1-3]: " ACCESS_CHOICE

case "$ACCESS_CHOICE" in
    1) ACCESS_ROLE="dcid_readonly" ;;
    2) ACCESS_ROLE="dcid_editor" ;;
    3) ACCESS_ROLE="dcid_maintainer" ;;
    *) echo "Lua chon khong hop le."; exit 1 ;;
esac

docker exec -i "$POSTGRES_CONTAINER" \
    psql -v ON_ERROR_STOP=1 -U dcid -d dcid \
    -v member_name="$MEMBER_NAME" -v access_role="$ACCESS_ROLE" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN INHERIT', :'member_name')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'member_name') \gexec

SELECT format('ALTER ROLE %I LOGIN INHERIT', :'member_name') \gexec
SELECT format(
    'REVOKE dcid_readonly, dcid_editor, dcid_maintainer FROM %I',
    :'member_name'
) \gexec
SELECT format('GRANT %I TO %I', :'access_role', :'member_name') \gexec
SQL

echo "Dat mat khau rieng cho $MEMBER_NAME (terminal se hoi hai lan):"
docker exec -it "$POSTGRES_CONTAINER" \
    psql -v ON_ERROR_STOP=1 -U dcid -d dcid \
    -c "\\password $MEMBER_NAME"

echo "Da cap role $ACCESS_ROLE cho $MEMBER_NAME."
echo "Khong chia se POSTGRES_PASSWORD cua ung dung cho thanh vien."
