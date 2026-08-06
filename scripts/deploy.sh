#!/bin/bash
# Usage: ./scripts/deploy.sh [--pull] [--build] [--restart]
set -e

COMPOSE_CMD="docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.production"

case "$1" in
  --pull)
    git pull origin main
    ;;
  --build)
    $COMPOSE_CMD build --no-cache
    ;;
  --restart)
    $COMPOSE_CMD up -d
    echo "Waiting for backend health..."
    sleep 10
    curl -f http://localhost:8080/api/health && echo "✓ Backend healthy" || echo "✗ Backend not healthy"
    ;;
  --full)
    git pull origin main
    $COMPOSE_CMD build --no-cache backend ai ai-ocr
    $COMPOSE_CMD up -d
    ;;
  --logs)
    $COMPOSE_CMD logs -f --tail=100
    ;;
  --status)
    $COMPOSE_CMD ps
    ;;
  *)
    echo "Usage: $0 [--pull|--build|--restart|--full|--logs|--status]"
    exit 1
    ;;
esac
