# Build stage
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .

ENV MAVEN_CONFIG=""
RUN ./mvnw dependency:go-offline -B

COPY src ./src

RUN ./mvnw clean package -DskipTests -B

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S dcid && adduser -S dcid -G dcid

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

RUN chown -R dcid:dcid /app

USER dcid

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
