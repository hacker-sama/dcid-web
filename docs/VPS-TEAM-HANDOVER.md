# Bàn giao VPS và PostgreSQL cho nhóm DCID

Tài liệu này giúp nhóm vận hành chung một VPS và một PostgreSQL mà không chia sẻ
mật khẩu `root`, mật khẩu database của ứng dụng hoặc file `.env.production`.

## 1. Kiến trúc quyền

| Đối tượng | Tài khoản | Quyền |
|---|---|---|
| Ứng dụng | PostgreSQL `dcid` | Chủ sở hữu schema; chỉ backend sử dụng |
| Thành viên xem dữ liệu | PostgreSQL cá nhân | `dcid_readonly` |
| Thành viên nhập/sửa dữ liệu | PostgreSQL cá nhân | `dcid_editor` |
| Nhóm trưởng | PostgreSQL cá nhân | `dcid_maintainer` |
| Nhóm trưởng | Linux cá nhân | SSH key, `sudo`, Docker |
| **GitHub Actions CI/CD** | Linux `ci-deploy` | SSH key, Docker, chỉ được sudo helper deploy Nginx |

Không dùng chung một username/mật khẩu PostgreSQL. Database vẫn là database chung
`dcid`, nhưng mỗi người có tài khoản riêng để có thể thu hồi quyền và truy vết.

> Thành viên nhóm trưởng thuộc nhóm `docker`. Quyền Docker gần tương đương quyền
> root, vì vậy chỉ cấp cho người thực sự chịu trách nhiệm vận hành VPS.
>
> User `ci-deploy` cũng thuộc nhóm `docker`, không có quyền `sudo` tổng quát và
> chỉ được chạy helper root-owned `/usr/local/sbin/dcid-deploy-nginx` để kiểm tra
> rồi reload cấu hình Nginx. User này chỉ SSH bằng key của GitHub Actions.

## 2. Trạng thái production chuẩn

- VPS: Ubuntu, IP `160.250.132.20`.
- Website HTTPS: `https://160.250.132.20.sslip.io`.
- Mã nguồn: `/opt/dcid`.
- Nginx phục vụ Flutter và chuyển `/api`, `/ws` vào backend.
- Backend chỉ bind `127.0.0.1:8080`.
- PostgreSQL chỉ bind `127.0.0.1:5433` để dùng qua SSH tunnel.
- Internet chỉ mở cổng 22, 80 và 443.
- Production có đúng 9 container: `dcid-postgres`, `dcid-redis`,
  `dcid-minio`, `dcid-qdrant`, `dcid-ollama`, `dcid-backend`, `dcid-ai`,
  `dcid-ai-worker`, `dcid-ai-ocr`.

## 3. Cấu hình Compose riêng cho VPS

Trên VPS:

```bash
cd /opt/dcid
cp docker-compose.vps.example.yml docker-compose.vps.yml
```

File này chỉ publish backend và PostgreSQL trên loopback. Không mở cổng 5433
trong UFW hoặc bảng firewall của DataZ.

Kiểm tra cấu hình:

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  -f docker-compose.vps.yml \
  config --quiet
```

Áp dụng:

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  -f docker-compose.vps.yml \
  up -d
```

## 4. Cấp quyền VPS cho nhóm trưởng

### 4.1 Tạo SSH key trên máy của nhóm trưởng

PowerShell Windows:

```powershell
ssh-keygen -t ed25519 -C "dcid-team-lead"
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
```

Chỉ sao chép dòng public key có đuôi `.pub`. Không gửi file `id_ed25519`.

### 4.2 Tạo tài khoản trên VPS

Người đang có quyền quản trị chạy:

```bash
cd /opt/dcid
chmod +x scripts/setup-vps-team-lead.sh
sudo ./scripts/setup-vps-team-lead.sh
```

Nhập username riêng của nhóm trưởng và dán public key khi được hỏi.

### 4.3 Kiểm tra trước khi đóng phiên hiện tại

Nhóm trưởng mở terminal mới:

```powershell
ssh <username-nhom-truong>@160.250.132.20
```

Trên VPS:

```bash
sudo whoami
docker ps --filter "name=dcid-"
```

Kết quả đầu tiên phải là `root`; danh sách sau phải có 9 container. Chỉ sau khi
hai kiểm tra này thành công mới đóng phiên quản trị cũ.

## 5. Tạo tài khoản PostgreSQL cho từng người

Trên VPS:

```bash
cd /opt/dcid
chmod +x scripts/create-postgres-member.sh
./scripts/create-postgres-member.sh
```

Script sẽ:

1. Tạo/cập nhật ba nhóm quyền chuẩn.
2. Hỏi username của thành viên.
3. Hỏi mức quyền `readonly`, `editor` hoặc `maintainer`.
4. Yêu cầu nhập mật khẩu riêng hai lần mà không hiện mật khẩu trên màn hình.

Khuyến nghị:

- Thành viên thông thường: `readonly`.
- Người phụ trách dữ liệu: `editor`.
- Nhóm trưởng: `maintainer`.
- Không cấp tài khoản PostgreSQL `dcid` và không gửi `POSTGRES_PASSWORD`.

Kiểm tra tài khoản và role:

```bash
docker exec -it dcid-postgres psql -U dcid -d dcid \
  -c "SELECT r.rolname AS username, g.rolname AS team_role
      FROM pg_auth_members m
      JOIN pg_roles r ON r.oid = m.member
      JOIN pg_roles g ON g.oid = m.roleid
      WHERE g.rolname LIKE 'dcid_%'
      ORDER BY r.rolname, g.rolname;"
```

## 6. Kết nối PostgreSQL trong Antigravity/Database Client

Trên máy thành viên, mở terminal và giữ lệnh này chạy:

```powershell
ssh -L 5433:127.0.0.1:5433 <username-linux>@160.250.132.20
```

Trong công cụ PostgreSQL của Antigravity nhập:

| Trường | Giá trị |
|---|---|
| Host | `127.0.0.1` |
| Port | `5433` |
| Database | `dcid` |
| Username | Tài khoản PostgreSQL cá nhân |
| Password | Mật khẩu PostgreSQL cá nhân |
| SSL phía client | Không bắt buộc; kết nối đã nằm trong SSH tunnel |

Không nhập IP VPS vào trường Host và không mở PostgreSQL ra Internet.

## 7. Cập nhật phiên bản trên VPS

**Thông thường:** Pipeline GitHub Actions tự động chạy khi có code mới vào `main`.
Xem kết quả tại: **GitHub → Actions → Deploy to Production**.

**Deploy thủ công (khi cần hotfix hoặc pipeline gặp sự cố):**

```bash
cd /opt/dcid
bash scripts/deploy.sh --status   # kiểm tra hiện trạng
bash scripts/deploy.sh --full     # pull + build + restart + health check
```

Xem đầy đủ các tùy chọn tại [DEPLOY-RUNBOOK.md](DEPLOY-RUNBOOK.md).

Không chạy `docker compose down -v`; tùy chọn `-v` xóa volume dữ liệu.

## 8. Kiểm tra vận hành

```bash
docker ps --filter "name=dcid-" \
  --format "table {{.Names}}\t{{.Status}}"
docker ps --filter "name=dcid-" -q | wc -l
curl -fsS http://127.0.0.1:8080/api/health
curl -I https://160.250.132.20.sslip.io
sudo systemctl is-active docker nginx fail2ban
```

Kết quả mong đợi: 9 container, backend `UP`, HTTPS phản hồi và ba dịch vụ hệ
thống đều `active`.

## 9. Thu hồi quyền khi thành viên rời nhóm

Khóa tài khoản PostgreSQL:

```bash
docker exec -it dcid-postgres psql -U dcid -d dcid
```

Trong `psql`:

```sql
ALTER ROLE <username_postgresql> NOLOGIN;
```

Với tài khoản Linux, nhóm trưởng kiểm tra đúng username trước rồi khóa đăng nhập:

```bash
sudo usermod --lock <username_linux>
sudo gpasswd -d <username_linux> docker
sudo gpasswd -d <username_linux> sudo
```

Không xóa tài khoản ngay nếu còn cần nhật ký hoặc file thuộc sở hữu của người đó.

## 10. Bí mật và backup

- `.env.production`, private SSH key và mật khẩu không được gửi qua chat hoặc
  commit lên Git.
- `ci-deploy` private key chỉ lưu trong GitHub Secrets; không chia sẻ qua kênh khác.
- Backup DataZ không thay thế backup ứng dụng.
- `scripts/backup.sh` hiện chỉ dump PostgreSQL; MinIO và các volume AI cần được
  sao lưu riêng trước khi coi quy trình backup là đầy đủ.
- Sau khi thay đổi quan trọng, tạo snapshot/backup từ trang quản trị DataZ.

## 11. CI/CD Pipeline

Nhóm dùng GitHub Actions với quy trình:

```
Nhánh cá nhân ──PR─▶ dev ──PR─▶ main ──auto─▶ Deploy VPS
```

| Workflow | Trigger | Việc làm |
|---|---|---|
| `ci.yml` | Mọi PR vào `dev`/`main`, push lên `dev` | Build backend + test, build Flutter, lint Python |
| `deploy.yml` | Push/merge vào `main` | Build → SCP Flutter → SSH deploy → health check → rollback nếu fail |

**GitHub Secrets cần thiết** (Settings → Secrets → Actions):

| Secret | Mô tả |
|---|---|
| `VPS_HOST` | `160.250.132.20` |
| `VPS_USER` | `ci-deploy` |
| `VPS_SSH_KEY` | Private key SSH của user `ci-deploy` |
| `VPS_PORT` | `22` |
| `API_BASE_URL` | `https://160.250.132.20.sslip.io` |

> `.env.production` **không** được inject qua CI. File này tồn tại trên VPS và
> được tạo thủ công một lần — pipeline chỉ pull code và rebuild Docker image.

Xem chi tiết vận hành tại [DEPLOY-RUNBOOK.md](DEPLOY-RUNBOOK.md).
