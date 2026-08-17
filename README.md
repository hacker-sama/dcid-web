# DCID — Digital Cognitive InDustrial System

[![CI](https://github.com/hacker-sama/dcid-web/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/hacker-sama/dcid-web/actions/workflows/ci.yml)
[![Deploy](https://github.com/hacker-sama/dcid-web/actions/workflows/deploy.yml/badge.svg?branch=main)](https://github.com/hacker-sama/dcid-web/actions/workflows/deploy.yml)

An on-premise digital assistant and industrial knowledge management system built on a local RAG architecture.

## Repository Structure

This is a monorepo containing three primary packages:

| Directory | Role |
|---|---|
| [`dcid-backend`](dcid-backend) | Governance / control plane (Spring Boot 3.3, Java 21): auth/RBAC, document management & versioning, audit trail (ISO), MinIO storage, WebSocket STOMP. |
| [`dcid-app`](dcid-app) | Cross-platform **Flutter** frontend — Web (Kiosk/Admin) + Mobile (Android). Includes RAG search, document upload, and document deletion with confirmation dialog. |
| [`dcid-ai`](dcid-ai) | AI plane (Python / FastAPI) — OCR/RAG/LLM, Qdrant vector DB, Celery/Redis, SSE streaming. |

## System Overview

The system follows a **Dual-Plane Local RAG** architecture with full on-premise isolation.

### Plane A — Official Document Governance

Manages structured internal documents such as SOPs, technical drawings, and factory regulations under ISO standards.

- **RBAC**: Role hierarchy `OPERATOR < ENGINEER < QA_ADMIN < ADMIN`. Documents are filtered based on the requesting user's minimum required role (`min_role`).
- **Version lifecycle**: Upload new versions (v2, v3, ...), publish as `ACTIVE` (automatically supersedes the previous active version), and mark outdated versions as `OBSOLETE`.

### Plane B — Anonymous Public Q&A (`/ask`)

Allows unauthenticated users to perform Q&A against their own uploaded PDF files without requiring a login.

- **Authentication**: No JWT Bearer header required. Sessions are authenticated via a randomly generated session token.
- **Data isolation**: Temporary files are stored under `sessions/{sessionId}/` in MinIO. Vectors are scoped to `sessionId` in Qdrant.
- **TTL cleanup**: A `@Scheduled` job runs every 10 minutes and purges expired sessions (older than 2 hours) — Qdrant vectors, MinIO files, and DB records.

## Documentation

| Document | Description |
|---|---|
| [Setup Guide](docs/SETUP.md) | Full setup instructions for new contributors — **start here** |
| [Architecture](docs/ARCHITECTURE.md) | System diagram, business flows, data model, API overview |
| [ERD & Database](docs/ERD.md) | Relational schema, Postgres/Qdrant/MinIO separation, version lifecycle |
| [API Contract BE↔AI](docs/API-CONTRACT.md) | Source of truth for ingest/query/callback boundaries |
| [VPS & Access Handover](docs/VPS-TEAM-HANDOVER.md) | Linux/PostgreSQL accounts, SSH tunnel, access revocation |
| [Deploy Runbook](docs/DEPLOY-RUNBOOK.md) | CI/CD operations, manual deploy, rollback, incident handling |
| [Thesis Plan (8 weeks)](docs/PLAN-THESIS.md) | Thesis framing, dataset, experiments, weekly schedule |
| [6-week Product Plan](docs/PLAN-6-WEEKS.md) | Product roadmap — superseded |
| [18-week Roadmap](docs/ROADMAP.md) | 5 milestones, team assignments, risk register |
| [Frontend Guide](docs/FRONTEND.md) | `dcid-app` architecture — web (kiosk/admin) + mobile |
| [Backend Dev Guide](dcid-backend/CLAUDE.md) | How to run, conventions, auth |

Work orders (completed):
- [Work order: dcid-ai setup](docs/PLAN-DCID-AI.md)
- [Work order: Flutter document screen + upload](docs/PLAN-FLUTTER-DOCS.md)

## Quick Start

See [docs/SETUP.md](docs/SETUP.md) for full prerequisites and step-by-step instructions. The following is a summary of the main startup sequence.

```bash
# 1. Infrastructure
docker compose up -d postgres minio qdrant ai-ocr redis

# 2. Backend (separate terminal)
cd dcid-backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
# Login: POST http://localhost:8080/api/auth/login  {"username":"admin","password":"admin123"}

# 3. AI service (two terminals)
# Terminal 1 — API server
cd dcid-ai && python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt && copy .env.example .env
uvicorn app.main:app --port 8000

# Terminal 2 — Celery worker
cd dcid-ai && .venv\Scripts\activate
celery -A app.celery_app.celery_app worker --loglevel=info -Q ingest,default

# 4. Frontend (separate terminal)
cd dcid-app && flutter pub get
# Web (kiosk/admin)
flutter run -d chrome --web-port=3000 --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080
# Mobile (Android)
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8080
```
