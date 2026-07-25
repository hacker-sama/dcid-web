# Build stage
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .
COPY .mvn .mvn

# Dùng mvn trực tiếp (image đã có Maven sẵn, không cần mvnw wrapper)
RUN mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -DskipTests -B

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S dcid && adduser -S dcid -G dcid

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

RUN chown -R dcid:dcid /app

USER dcid

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
