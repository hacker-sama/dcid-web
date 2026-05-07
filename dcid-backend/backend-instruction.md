You are an expert Spring Boot architect. Your task is to scaffold a 
production-grade Spring Boot backend for a Vietnamese e-Government platform 
called "CongDanSo" (DCID Platform). This is a two-sided platform: citizens 
submit administrative applications, officers review and process them.

## STRICT RULES — follow exactly, no deviation
- Do NOT generate any feature business logic. Scaffold structure only.
- Do NOT use lombok unless explicitly stated.
- Every file must compile with zero errors.
- Every placeholder method must throw UnsupportedOperationException with 
  a TODO comment, never return null silently.
- All configuration must come from application.yml, never hardcoded.
- After creating all files, run: ./mvnw clean compile
  Fix any compilation errors before finishing.

---

## TECH STACK

- Java 21 (use records, sealed classes, text blocks where appropriate)
- Spring Boot 3.3.x
- Spring Security 6 + OAuth2 Resource Server (Keycloak JWT validation)
- Spring Data JPA + Hibernate 6
- Spring Kafka
- Spring Data Redis
- Spring WebSocket (STOMP)
- Flyway (database migration)
- PostgreSQL driver
- Micrometer + Prometheus actuator
- SpringDoc OpenAPI 3 (swagger-ui)
- JavaMailSender
- MinIO Java SDK 8.x
- Maven (not Gradle)
- Docker + Docker Compose

---

## PROJECT STRUCTURE TO CREATE

Create the following directory and file structure exactly:

dcid-backend/
├── .mvn/wrapper/
│   └── maven-wrapper.properties
├── src/
│   ├── main/
│   │   ├── java/vn/dcid/
│   │   │   ├── DCIDApplication.java
│   │   │   │
│   │   │   ├── config/
│   │   │   │   ├── SecurityConfig.java
│   │   │   │   ├── JwtClaimsConverter.java
│   │   │   │   ├── FlywayConfig.java
│   │   │   │   ├── KafkaConfig.java
│   │   │   │   ├── RedisConfig.java
│   │   │   │   ├── MinioConfig.java
│   │   │   │   ├── WebSocketConfig.java
│   │   │   │   └── OpenApiConfig.java
│   │   │   │
│   │   │   ├── common/
│   │   │   │   ├── ApiResponse.java          ← generic wrapper: {data, meta}
│   │   │   │   ├── ErrorResponse.java        ← {code, message, traceId, errors}
│   │   │   │   ├── FieldError.java           ← {field, message}
│   │   │   │   ├── PagedResponse.java        ← {items, page, size, total}
│   │   │   │   ├── PageRequest.java          ← {page, size, sort}
│   │   │   │   └── AuditableEntity.java      ← @MappedSuperclass with 
│   │   │   │                                    createdAt, updatedAt, createdBy
│   │   │   │
│   │   │   ├── exception/
│   │   │   │   ├── GlobalExceptionHandler.java   ← @RestControllerAdvice
│   │   │   │   ├── AppException.java             ← base runtime exception
│   │   │   │   ├── NotFoundException.java
│   │   │   │   ├── ForbiddenException.java
│   │   │   │   ├── ConflictException.java
│   │   │   │   ├── PolicyViolationException.java
│   │   │   │   └── RateLimitException.java
│   │   │   │
│   │   │   ├── security/
│   │   │   │   ├── SecurityContextHelper.java   ← getCurrentUserId(), 
│   │   │   │   │                                   getCurrentRole(), 
│   │   │   │   │                                   hasRole(String)
│   │   │   │   └── UserPrincipal.java           ← record holding JWT claims
│   │   │   │
│   │   │   ├── filter/
│   │   │   │   ├── RequestTracingFilter.java    ← MDC traceId injection
│   │   │   │   └── RateLimitFilter.java         ← Redis-based per-user limit
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── enums/
│   │   │   │   │   ├── ApplicationStatus.java   ← DRAFT, SUBMITTED, IN_REVIEW,
│   │   │   │   │   │                               PENDING_SUPPLEMENT, APPROVED,
│   │   │   │   │   │                               REJECTED, WITHDRAWN
│   │   │   │   │   │   Include: canTransitionTo(ApplicationStatus next) method
│   │   │   │   │   │   with full state machine map
│   │   │   │   │   ├── UserRole.java            ← CITIZEN, OFFICER, 
│   │   │   │   │   │                               SUPERVISOR, ADMIN
│   │   │   │   │   └── NotificationType.java    ← APPLICATION_SUBMITTED,
│   │   │   │   │                                   STATUS_CHANGED,
│   │   │   │   │                                   SUPPLEMENT_REQUIRED,
│   │   │   │   │                                   APPOINTMENT_REMINDER
│   │   │   │   │
│   │   │   │   └── entity/
│   │   │   │       ├── User.java
│   │   │   │       ├── CitizenProfile.java
│   │   │   │       ├── OfficerProfile.java
│   │   │   │       ├── ProcedureType.java       ← includes jsonSchema TEXT column
│   │   │   │       ├── Application.java         ← includes status, assignedOfficer,
│   │   │   │       │                               applicant FK, procedureType FK
│   │   │   │       ├── ApplicationDocument.java ← minioKey, originalFilename,
│   │   │   │       │                               contentType, fileSizeBytes
│   │   │   │       ├── ApplicationStatusHistory.java
│   │   │   │       ├── Notification.java
│   │   │   │       ├── Appointment.java
│   │   │   │       └── AuditLog.java            ← actorId, action, resourceType,
│   │   │   │                                       resourceId, ipAddress, detail JSON
│   │   │   │
│   │   │   ├── repository/
│   │   │   │   ├── UserRepository.java
│   │   │   │   ├── CitizenProfileRepository.java
│   │   │   │   ├── OfficerProfileRepository.java
│   │   │   │   ├── ProcedureTypeRepository.java
│   │   │   │   ├── ApplicationRepository.java   ← custom query stubs:
│   │   │   │   │   findByApplicantId, findByAssignedOfficerIdAndStatus,
│   │   │   │   │   countPendingByApplicant, findOverdue
│   │   │   │   ├── ApplicationDocumentRepository.java
│   │   │   │   ├── ApplicationStatusHistoryRepository.java
│   │   │   │   ├── NotificationRepository.java
│   │   │   │   ├── AppointmentRepository.java
│   │   │   │   └── AuditLogRepository.java
│   │   │   │
│   │   │   ├── dto/
│   │   │   │   ├── request/
│   │   │   │   │   ├── SubmitApplicationRequest.java   ← Bean Validation annotations
│   │   │   │   │   ├── UpdateApplicationRequest.java
│   │   │   │   │   ├── ReviewApplicationRequest.java   ← action, note, missingDocs
│   │   │   │   │   ├── CreateProcedureRequest.java
│   │   │   │   │   └── BookAppointmentRequest.java
│   │   │   │   └── response/
│   │   │   │       ├── ApplicationDTO.java
│   │   │   │       ├── ApplicationDetailDTO.java       ← includes statusHistory list
│   │   │   │       ├── ProcedureTypeDTO.java
│   │   │   │       ├── ProcedureDetailDTO.java         ← includes jsonSchema
│   │   │   │       ├── UserProfileDTO.java
│   │   │   │       ├── NotificationDTO.java
│   │   │   │       └── AppointmentDTO.java
│   │   │   │
│   │   │   ├── service/
│   │   │   │   ├── ApplicationService.java      ← stub all methods, 
│   │   │   │   │                                   enforce policy + auth checks
│   │   │   │   ├── ApplicationPolicy.java       ← assertCanSubmit, assertCanApprove,
│   │   │   │   │                                   assertCanWithdraw, assertCanReview
│   │   │   │   ├── ProcedureService.java
│   │   │   │   ├── NotificationService.java
│   │   │   │   ├── AppointmentService.java
│   │   │   │   ├── AuditLogService.java         ← log() method, async @Async
│   │   │   │   ├── MinioService.java            ← upload(), getPresignedUrl(),
│   │   │   │   │                                   delete()
│   │   │   │   └── UserService.java
│   │   │   │
│   │   │   ├── messaging/
│   │   │   │   ├── event/
│   │   │   │   │   └── ApplicationEvent.java    ← record: eventType, applicationId,
│   │   │   │   │                                   applicantId, status, timestamp
│   │   │   │   ├── ApplicationEventProducer.java
│   │   │   │   └── ApplicationEventConsumer.java  ← @KafkaListener stub,
│   │   │   │                                        handles DLQ pattern
│   │   │   │
│   │   │   ├── websocket/
│   │   │   │   └── ApplicationStatusWebSocketHandler.java
│   │   │   │
│   │   │   └── api/
│   │   │       ├── HealthController.java        ← GET /api/health
│   │   │       ├── AuthController.java          ← GET /api/auth/me
│   │   │       ├── citizen/
│   │   │       │   ├── CitizenApplicationController.java
│   │   │       │   ├── CitizenProcedureController.java
│   │   │       │   ├── CitizenNotificationController.java
│   │   │       │   └── CitizenAppointmentController.java
│   │   │       └── officer/
│   │   │           ├── OfficerApplicationController.java
│   │   │           ├── OfficerDashboardController.java
│   │   │           ├── AdminProcedureController.java
│   │   │           ├── AdminUserController.java
│   │   │           └── AuditLogController.java
│   │   │
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       ├── logback-spring.xml            ← JSON logging with traceId MDC
│   │       └── db/migration/
│   │           ├── V1__create_users.sql
│   │           ├── V2__create_procedures.sql
│   │           ├── V3__create_applications.sql
│   │           ├── V4__create_notifications_appointments.sql
│   │           ├── V5__create_audit_logs.sql
│   │           └── V6__create_indexes.sql
│   │
│   └── test/java/vn/dcid/
│       ├── DCIDApplicationTests.java     ← context loads test
│       ├── service/
│       │   └── ApplicationPolicyTest.java     ← unit tests for state machine
│       └── api/
│           └── HealthControllerTest.java      ← @WebMvcTest
│
├── Dockerfile
├── .env.example
├── pom.xml
└── CLAUDE.md                                  ← instructions for future Claude Code
                                                  sessions on this project

---

## KEY IMPLEMENTATION DETAILS

### SecurityConfig.java
Configure Spring Security as OAuth2 Resource Server:
- Validate JWT against Keycloak JWKS endpoint (from application.yml)
- Extract roles from realm_access.roles claim
- Public endpoints: GET /api/health, GET /actuator/prometheus
- All other endpoints require authentication
- CORS: allow configured origins from application.yml
- CSRF: disabled (stateless JWT)
- Session: STATELESS

### ApplicationStatus.java — state machine
Implement canTransitionTo() with this exact map:
DRAFT               → [SUBMITTED, WITHDRAWN]
SUBMITTED           → [IN_REVIEW, WITHDRAWN]
IN_REVIEW           → [PENDING_SUPPLEMENT, APPROVED, REJECTED]
PENDING_SUPPLEMENT  → [SUBMITTED, WITHDRAWN]
APPROVED            → [] (terminal)
REJECTED            → [] (terminal)
WITHDRAWN           → [] (terminal)

### GlobalExceptionHandler.java
Handle ALL these exceptions and map to correct HTTP status:
- MethodArgumentNotValidException     → 422 VALIDATION_FAILED
- ConstraintViolationException        → 422 VALIDATION_FAILED
- NotFoundException                   → 404 NOT_FOUND
- ForbiddenException                  → 403 FORBIDDEN
- ConflictException                   → 409 CONFLICT
- PolicyViolationException            → 422 POLICY_VIOLATION
- RateLimitException                  → 429 RATE_LIMIT_EXCEEDED
  (add Retry-After header)
- AccessDeniedException               → 403 FORBIDDEN
- AuthenticationException             → 401 UNAUTHORIZED
- Throwable (catch-all)               → 500 INTERNAL_ERROR
  (log full stacktrace, do NOT expose detail to client,
   include traceId from MDC in response)

### application.yml structure
spring:
  application.name: congdan-so-backend
  datasource:
    url: ${POSTGRES_URL}
    username: ${POSTGRES_USER}
    password: ${POSTGRES_PASSWORD}
  jpa:
    hibernate.ddl-auto: validate
    show-sql: false
    properties.hibernate.format_sql: true
  security.oauth2.resourceserver.jwt:
    jwk-set-uri: ${KEYCLOAK_JWKS_URI}
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS}
    consumer.group-id: congdan-so
  data.redis:
    host: ${REDIS_HOST}
    port: ${REDIS_PORT:6379}
  mail:
    host: ${MAIL_HOST}
    port: ${MAIL_PORT:587}

app:
  cors.allowed-origins: ${CORS_ALLOWED_ORIGINS}
  minio:
    endpoint: ${MINIO_ENDPOINT}
    access-key: ${MINIO_ACCESS_KEY}
    secret-key: ${MINIO_SECRET_KEY}
    bucket: ${MINIO_BUCKET:dcid}
  rate-limit:
    submissions-per-hour: ${RATE_LIMIT_SUBMISSIONS:10}
  keycloak:
    admin-url: ${KEYCLOAK_ADMIN_URL}
    realm: ${KEYCLOAK_REALM:dcid}

management:
  endpoints.web.exposure.include: health,prometheus,info
  metrics.export.prometheus.enabled: true

### Flyway migrations — write complete SQL, not placeholders
V1: users table (id UUID PK, keycloak_id VARCHAR UNIQUE, email, 
    role UserRole enum, is_active, created_at, updated_at)
V2: procedure_types (id UUID, code VARCHAR UNIQUE, name, description,
    json_schema TEXT, estimated_days INT, fee NUMERIC, is_active,
    created_at, updated_at)
V3: applications + application_documents + application_status_history
    (full schema with all FK constraints and check constraints on status)
V4: notifications + appointments
V5: audit_logs (id UUID, actor_id UUID, action VARCHAR, resource_type,
    resource_id UUID, ip_address, detail JSONB, created_at)
    NOTE: NO updated_at — audit log is immutable
V6: all indexes as discussed (composite, partial indexes)

### CLAUDE.md — write this file with:
- Project overview (2–3 sentences)
- How to run locally (commands)
- Package structure explanation
- Coding conventions (naming, error handling patterns)
- How to add a new feature (step-by-step checklist)
- Common pitfalls to avoid

### Dockerfile
Multi-stage build:
Stage 1 (builder): maven:3.9-eclipse-temurin-21, run mvn package -DskipTests
Stage 2 (runtime): eclipse-temurin:21-jre-alpine
EXPOSE 8080
Non-root user

---

## WHAT NOT TO DO
- Do not implement actual business logic in services — stubs only
- Do not generate frontend code
- Do not use Spring Boot 2.x APIs (use 3.x equivalents)
- Do not use javax.* imports (use jakarta.* only)
- Do not hardcode any URL, credential, or environment-specific value
- Do not create a docker-compose.yml (that is handled separately)

---

## VERIFICATION STEPS
After creating all files:
1. Run: ./mvnw clean compile
2. If compilation fails, fix ALL errors before stopping
3. Run: ./mvnw test -pl . -Dtest=DCIDApplicationTests
4. Report: list every file created with its line count