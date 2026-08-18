# CLAUDE.md — DCID: Digital Cognitive InDustrial System Backend

## Project Overview

DCID backend is the **on-premise governance / control plane** for the **DCID: Digital Cognitive InDustrial System**
(industrial document assistant & knowledge engine). Built with Spring Boot 3.3.x
on Java 21. It owns everything that is *not* AI inference:

- **AuthN/AuthZ** — self-issued JWT (HMAC) + role-based access control (no external IdP).
- **Document & version lifecycle** — metadata, versioning workflow, obsolete marking (planned).
- **Object storage** — original PDFs and bounding-box crops in MinIO.
- **Audit logging** — immutable ISO-traceable trail (who / when / what / version).
- **Integration** — REST surface for CMMS/MES work orders (planned).
- **Orchestration** — calls out to a separate Python AI service for OCR / RAG / LLM (planned).

> The AI plane (PaddleOCR, embeddings, ChromaDB, llama.cpp/GGUF, guardrails) lives in a
> **separate Python (FastAPI/Celery) service** and is intentionally NOT in this repo yet.
> See `docs/ARCHITECTURE.md` at the repo root for the full target architecture and roadmap.

**Current state:** the codebase was reset to a clean skeleton. The old e-government
(citizen/officer) domain has been removed. What remains is cross-cutting infrastructure plus a
working self-JWT auth flow. Business domain (documents, versions, query logs, work orders) is
**not built yet** — it is designed in `docs/ARCHITECTURE.md` and should be added incrementally.

## How to Run Locally

```bash
# Prerequisites: JDK 21+, Docker (PostgreSQL, Redis, Kafka, MinIO)

# 1. Start infra (from repo root)
docker-compose up -d postgres redis minio kafka zookeeper

# 2. Build & run (dev profile)
cd dcid-backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# 3. Log in with the seeded bootstrap admin (change the password!)
curl -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}'
# → { "data": { "token": "<jwt>", "tokenType": "Bearer", ... } }

curl http://localhost:8080/api/auth/me -H "Authorization: Bearer <jwt>"
```

Swagger UI: `http://localhost:8080/swagger-ui.html`

## Package Structure

```
vn.dcid/                          — (package name kept from the original repo)
├── DCIDApplication.java          — Spring Boot entry point (@EnableJpaAuditing, @EnableAsync)
├── config/                       — Security (self-JWT), Kafka, Redis, MinIO, OpenAPI, WebSocket,
│                                    Flyway, JwtProperties, DataInitializer (seeds bootstrap admin)
├── common/                       — Shared records: ApiResponse, ErrorResponse, PagedResponse,
│                                    PageRequest, ValidationError, AuditableEntity
├── exception/                    — Exception hierarchy + GlobalExceptionHandler
├── security/                     — JwtService (issue/verify), JwtAuthenticationFilter,
│                                    UserPrincipal, SecurityContextHelper
├── filter/                       — RequestTracingFilter, RateLimitFilter (Redis; disabled until
│                                    write endpoints exist)
├── domain/
│   ├── enums/                    — UserRole (OPERATOR, ENGINEER, QA_ADMIN, ADMIN)
│   └── entity/                   — User, AuditLog
├── repository/                   — UserRepository, AuditLogRepository
├── dto/
│   ├── request/                  — LoginRequest
│   └── response/                 — LoginResponse, UserProfileDTO
├── service/                      — AuthService, UserService, AuditLogService, MinioService
├── api/
    ├── HealthController          — public GET /api/health
    ├── AuthController            — POST /api/auth/login, GET /api/auth/me
    └── UserController            — Admin User Management CRUD (/api/admin/users)
```


## Authentication & RBAC

- **Self-issued JWT** (HS256 via jjwt). No Keycloak / no external IdP → fits air-gapped factories.
- `AuthService.login` verifies BCrypt password, `JwtService.issueToken` mints the token
  (subject = user id; claims `username`, `role`).
- `JwtAuthenticationFilter` validates `Authorization: Bearer <jwt>` and populates the
  `SecurityContext` with a `UserPrincipal` + a `ROLE_<role>` authority.
- Protect endpoints with `@PreAuthorize("hasRole('ENGINEER')")` (method security is enabled) or
  path rules in `SecurityConfig`.
- Config lives under `app.jwt.*` — **always override `APP_JWT_SECRET`** (>= 32 bytes) per env.

## Coding Conventions

### Naming
- **Packages**: lowercase, singular (`domain.entity`, not `domain.entities`)
- **Entities**: PascalCase, singular (`User`, not `Users`)
- **DTOs**: Suffix `DTO` for responses, `Request` for inputs
- **Controllers**: name by resource/context (`AuthController`, later e.g. `DocumentController`)

### Error Handling
- Custom exceptions extend `AppException` (carries a `code`); `GlobalExceptionHandler` maps them.
- Never return `null` — throw `NotFoundException` instead.
- Validation uses Jakarta Bean Validation annotations on request DTOs.

### Database
- Flyway manages schema in `db/migration/V{N}__description.sql`; baseline is `V1__init.sql`.
- JPA `ddl-auto=validate` — schema changes go through Flyway only.
- Use `Instant` for timestamps, never `LocalDateTime`.

### Stub Pattern (for not-yet-built domain)
- New service methods that aren't implemented yet should throw
  `UnsupportedOperationException("TODO: ...")` so compilation succeeds and work is greppable.

## How to Add a New Feature (e.g. Documents)

1. **Entity** in `domain/entity/`, extending `AuditableEntity` if it needs id/timestamps.
2. **Migration** `V{next}__description.sql`.
3. **Repository** in `repository/`.
4. **DTOs** in `dto/request` and `dto/response` (records).
5. **Service** with constructor injection (stub methods first).
6. **Controller** in `api/`, guard with `@PreAuthorize`.
7. **Test** — unit-test business logic; keep web-slice tests infra-free (see `HealthControllerTest`).

## Testing Notes
- `HealthControllerTest` is a plain unit test (no context) — always green.
- `DCIDApplicationTests` is `@SpringBootTest` (context load) and **requires the infra stack**
  (Postgres/Redis/Kafka/MinIO) to be up. Run it only with `docker-compose up -d` first.

## Common Pitfalls to Avoid
- **DO NOT** use `javax.*` — use `jakarta.*` (Spring Boot 3.x).
- **DO NOT** reintroduce Keycloak/OAuth2 — auth is self-contained JWT by design.
- **DO NOT** put AI inference (OCR/RAG/LLM) in this service — it belongs in the Python plane.
- **DO NOT** use Lombok — write getters/setters explicitly.
- **DO NOT** use `LocalDateTime` — use `Instant`.
- **DO NOT** modify schema directly — always use Flyway.
- **DO NOT** hardcode secrets — override `APP_JWT_SECRET` and DB creds via env.
