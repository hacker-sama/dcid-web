# Hướng dẫn vận hành DCID — Deploy Runbook

> Tài liệu này dành cho nhóm trưởng. Không cần đọc thuộc — chỉ cần biết nó ở đây khi cần.

---

## 1. Luồng CI/CD bình thường

```
Nhánh cá nhân  ──PR──▶  dev   (CI check: build + test)
                         │
                    PR được review
                         │
                         ▼
                        main  ──auto──▶  GitHub Actions  ──▶  VPS 160.250.132.20
```

**CI check** (tự động trên mọi PR):
- Backend: Maven build + unit test
- Flutter: compile web
- AI: Python lint cơ bản

**CD deploy** (tự động khi merge vào `main`):
1. Build backend JAR
2. Build Flutter web
3. SCP Flutter lên VPS
4. SSH: `git pull` → `docker compose build` → `docker compose up -d`
5. Health check × 8 lần (mỗi lần 10 giây)
6. Nếu fail → tự rollback về commit trước

**Xem kết quả deploy:** GitHub → tab Actions → workflow "Deploy to Production"

---

## 2. Deploy thủ công (hotfix / emergency)

SSH vào VPS rồi chạy:

```bash
cd /opt/dcid

# Xem trạng thái hiện tại
bash scripts/deploy.sh --status

# Full deploy (pull + build + restart + health check)
bash scripts/deploy.sh --full

# Chỉ restart (không pull/build — dùng khi fix config)
bash scripts/deploy.sh --restart

# Xem log realtime
bash scripts/deploy.sh --logs
```

---

## 3. Rollback thủ công

```bash
cd /opt/dcid

# Xem lịch sử commit
git log --oneline -10

# Rollback về commit trước
bash scripts/deploy.sh --rollback HEAD~1

# Rollback về commit cụ thể
bash scripts/deploy.sh --rollback abc1234

# Rollback về tag version
bash scripts/deploy.sh --rollback v1.2.0
```

Sau rollback, kiểm tra:

```bash
bash scripts/deploy.sh --status
curl -sf http://127.0.0.1:8080/api/health && echo "OK"
```

---

## 4. Kiểm tra nhanh hệ thống

```bash
# 9 container đang chạy?
docker ps --filter "name=dcid-" --format "table {{.Names}}\t{{.Status}}"
docker ps --filter "name=dcid-" -q | wc -l   # phải = 9

# Backend health
curl -sf http://127.0.0.1:8080/api/health

# HTTPS từ internet
curl -I https://160.250.132.20.sslip.io

# 3 service hệ thống
sudo systemctl is-active docker nginx fail2ban

# RAM sử dụng
docker stats --no-stream
```

---

## 5. Khi GitHub Actions fail

**Xem nguyên nhân:**
1. Vào GitHub → Actions → job bị fail → xem log từng step
2. Step "Build & Test" fail → lỗi code, không phải lỗi infrastructure
3. Step "Deploy on VPS" fail → xem phần SSH output

**Deploy fail, rollback đã chạy:**
- Pipeline tự rollback — hệ thống đang ở commit cũ
- Fix lỗi trong code, push lại → trigger deploy mới

**Deploy fail, rollback cũng fail (hiếm gặp):**
```bash
# SSH vào VPS, kiểm tra từng container
docker ps -a --filter "name=dcid-"
docker logs dcid-backend --tail=50
docker logs dcid-ai --tail=50

# Restart thủ công
cd /opt/dcid
bash scripts/deploy.sh --restart
```

---

## 6. Cài đặt một lần (setup ban đầu)

### 6.1 Tạo CI user trên VPS

```bash
# SSH vào VPS với quyền sudo
cd /opt/dcid
sudo bash scripts/setup-ci-user.sh
# Làm theo hướng dẫn in ra màn hình
```

### 6.2 GitHub Secrets cần thiết

Vào: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret | Giá trị |
|---|---|
| `VPS_HOST` | `160.250.132.20` |
| `VPS_USER` | `ci-deploy` |
| `VPS_SSH_KEY` | Nội dung file `~/.ssh/dcid_ci_deploy` (private key) |
| `VPS_PORT` | `22` |
| `API_BASE_URL` | `https://160.250.132.20.sslip.io` |

> **Lưu ý quan trọng:** `.env.production` **KHÔNG** được đưa vào GitHub Secrets hay GitHub Actions. File này chỉ tồn tại trên VPS và được tạo thủ công một lần. Pipeline chỉ pull code và rebuild Docker images.

### 6.3 Tạo GitHub Environment (tùy chọn, khuyến nghị)

GitHub → Settings → Environments → New environment → Đặt tên `production`

Có thể cài:
- **Required reviewers**: ai đó phải approve trước khi deploy chạy
- **Wait timer**: delay N phút sau khi merge mới deploy

### 6.4 Test pipeline lần đầu

```bash
# Trên máy local: tạo nhánh test
git checkout -b test/ci-pipeline
echo "# test" >> README.md
git commit -am "test: trigger CI pipeline"
git push origin test/ci-pipeline

# Tạo PR vào dev → xem CI check chạy
# Sau khi CI pass, merge dev → main → xem Deploy chạy
```

---

## 7. Backup thủ công

```bash
# PostgreSQL dump (script đã có crontab 2h sáng mỗi ngày)
bash /opt/dcid/scripts/backup.sh

# Kiểm tra backup gần nhất
ls -lh /opt/dcid/backups/
```

> **Lưu ý:** MinIO và Qdrant chưa có backup tự động. Snapshot từ trang quản trị DataZ sau mỗi deploy quan trọng.

---

## 8. Contacts

| Vai trò | Trách nhiệm |
|---|---|
| Nhóm trưởng | Merge PR vào main, approve deploy nếu có protection |
| Mọi thành viên | Push lên nhánh cá nhân, tạo PR vào dev |
