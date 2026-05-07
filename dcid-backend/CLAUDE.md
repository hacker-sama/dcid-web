# CLAUDE.md — CongDanSo (DCID) Backend

## Project Overview

CongDanSo (DCID Platform) is a Vietnamese e-Government platform backend built with Spring Boot 3.3.x.
It serves as a two-sided platform where citizens submit administrative applications and officers
review and process them. The backend uses OAuth2/JWT (Keycloak) for authentication, PostgreSQL for
persistence, Kafka for event-driven processing, Redis for caching/rate-limiting, and MinIO for
document storage.

## How to Run Locally

```bash
# Prerequisites: JDK 21, Docker (for PostgreSQL, Redis, Kafka, MinIO, Keycloak)

# 1. Copy and configure environment variables
cp .env.example .env
# Edit .env with your local configuration

# 2. Start infrastructure services (if you have docker-compose elsewhere)
# docker-compose up -d

# 3. Build the project
./mvnw clean compile

# 4. Run tests
./mvnw test

# 5. Run the application
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

## Package Structure

```
vn.dcid/
├── DCIDApplication.java          — Spring Boot entry point
├── config/                       — Configuration classes (Security, Kafka, Redis, MinIO, etc.)
├── common/                       — Shared records: ApiResponse, ErrorResponse, PagedResponse, AuditableEntity
├── exception/                    — Exception hierarchy + GlobalExceptionHandler
├── security/                     — JWT UserPrincipal, SecurityContextHelper
├── filter/                       — Request filters (tracing, rate limiting)
├── domain/
│   ├── enums/                    — ApplicationStatus (state machine), UserRole, NotificationType
│   └── entity/                   — JPA entities (User, Application, ProcedureType, etc.)
├── repository/                   — Spring Data JPA repositories
├── dto/
│   ├── request/                  — Inbound DTOs with Bean Validation
│   └── response/                 — Outbound DTOs (records)
├── service/                      — Business logic stubs + ApplicationPolicy
├── messaging/
│   ├── event/                    — Kafka event records
│   ├── ApplicationEventProducer  — Kafka producer
│   └── ApplicationEventConsumer  — Kafka consumer with DLQ pattern
├── websocket/                    — STOMP WebSocket handler for real-time updates
└── api/
    ├── HealthController           — Public health check
    ├── AuthController             — GET /api/auth/me
    ├── citizen/                   — Citizen-facing endpoints
    └── officer/                   — Officer/admin endpoints
```

## Coding Conventions

### Naming
- **Packages**: lowercase, singular (`domain.entity`, not `domain.entities`)
- **Entities**: PascalCase, singular (`User`, not `Users`)
- **DTOs**: Suffix with `DTO` for responses, `Request` for inputs
- **Controllers**: Prefix with role context (`CitizenApplicationController`, `OfficerApplicationController`)

### Error Handling
- All custom exceptions extend `AppException` which carries a `code` field
- `GlobalExceptionHandler` maps exceptions to HTTP status codes
- Never return `null` — throw `NotFoundException` instead
- Validation uses Jakarta Bean Validation annotations on request DTOs

### Stub Pattern
- All service methods throw `UnsupportedOperationException("TODO: ...")` until implemented
- This ensures compilation succeeds and makes unfinished work easy to grep for

### Database
- Flyway manages schema migrations in `db/migration/V{N}__description.sql`
- JPA ddl-auto is set to `validate` — schema changes go through Flyway only
- Use `Instant` for timestamps, never `LocalDateTime`

### Security
- All endpoints require JWT authentication except health/actuator/swagger
- Roles extracted from Keycloak `realm_access.roles` claim
- Use `SecurityContextHelper` to get current user info in services

## How to Add a New Feature

1. **Entity**: Create JPA entity in `domain/entity/`, extending `AuditableEntity` if needed
2. **Migration**: Add Flyway migration `V{next}__description.sql`
3. **Repository**: Create Spring Data repository in `repository/`
4. **DTO**: Create request/response records in `dto/request/` and `dto/response/`
5. **Service**: Create service class with constructor injection, add stub methods
6. **Policy** (if needed): Add authorization checks in a policy class
7. **Controller**: Create REST controller in `api/citizen/` or `api/officer/`
8. **Test**: Add unit test for business logic, `@WebMvcTest` for controllers

## Common Pitfalls to Avoid

- **DO NOT** use `javax.*` imports — use `jakarta.*` only (Spring Boot 3.x)
- **DO NOT** hardcode URLs, credentials, or environment-specific values
- **DO NOT** use Lombok — write getters/setters explicitly
- **DO NOT** implement business logic before the skeleton is complete
- **DO NOT** use `LocalDateTime` — use `Instant` for all timestamps
- **DO NOT** modify schema directly — always use Flyway migrations
- **DO NOT** return `null` from service methods — throw appropriate exceptions
- **DO NOT** catch exceptions silently — log them or rethrow
