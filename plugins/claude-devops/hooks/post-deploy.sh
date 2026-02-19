#!/bin/bash
#
# Post-Deploy Health Check Hook
# Runs after git push to main, validates deployment health
#

# Configuration — detect project health URL dynamically
PROJECT_NAME=$(basename "$PWD")
case "$PROJECT_NAME" in
  influos) HEALTH_URL="https://influos.app/api/health" ;;
  whatsgo) HEALTH_URL="https://whatsgo.app/api/health" ;;
  *) HEALTH_URL="${DEPLOY_HEALTH_URL:-}" ;;
esac

if [ -z "$HEALTH_URL" ]; then
  echo "[post-deploy] No health URL configured for $PROJECT_NAME. Skipping health check."
  exit 0
fi

WAIT_SECONDS=45
MAX_RETRIES=3
RETRY_INTERVAL=10

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log() {
  echo -e "[post-deploy] $1"
}

# Wait for deployment to propagate
log "${YELLOW}Waiting ${WAIT_SECONDS}s for deployment to propagate...${NC}"
sleep "$WAIT_SECONDS"

# Health check with retries
for i in $(seq 1 $MAX_RETRIES); do
  log "Health check attempt $i/$MAX_RETRIES..."

  response=$(curl -s -w "\n%{http_code}" "$HEALTH_URL" 2>/dev/null)
  http_code=$(echo "$response" | tail -n 1)
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" = "200" ]; then
    status=$(echo "$body" | jq -r '.status' 2>/dev/null)
    db_status=$(echo "$body" | jq -r '.services.database' 2>/dev/null)
    redis_status=$(echo "$body" | jq -r '.services.redis' 2>/dev/null)

    if [ "$status" = "healthy" ]; then
      log "${GREEN}✓ Deployment healthy${NC}"
      log "  Database: $db_status"
      log "  Redis: $redis_status"
      exit 0
    elif [ "$status" = "degraded" ]; then
      log "${YELLOW}⚠ Deployment degraded${NC}"
      log "  Database: $db_status"
      log "  Redis: $redis_status"
      exit 0
    fi
  fi

  if [ $i -lt $MAX_RETRIES ]; then
    log "${YELLOW}Retry in ${RETRY_INTERVAL}s...${NC}"
    sleep "$RETRY_INTERVAL"
  fi
done

# All retries failed
log "${RED}✗ Health check failed after $MAX_RETRIES attempts${NC}"
log "  Last HTTP status: $http_code"
log "  URL: $HEALTH_URL"
log ""
log "Rollback options:"
log "  1. git revert HEAD && git push"
log "  2. Coolify dashboard: Redeploy previous version"
exit 1
