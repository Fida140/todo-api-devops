#!/usr/bin/env bash
# Smoke test : verifie que l'API repond correctement
# Usage : ./smoke_test.sh [BASE_URL] [FICHIER_RESULTAT]
BASE_URL="${1:-http://localhost:5000}"
REPORT="${2:-smoke-results.txt}"
PASSED=0
FAILED=0

: > "$REPORT"
log() { echo "$1" | tee -a "$REPORT"; }

# Attente que l'API soit prete (max 30 s)
for i in $(seq 1 30); do
  if curl -s -o /dev/null "$BASE_URL/health"; then break; fi
  sleep 1
done

check() {
  local name="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    log "[PASSED] $name (attendu=$expected, obtenu=$actual)"
    PASSED=$((PASSED+1))
  else
    log "[FAILED] $name (attendu=$expected, obtenu=$actual)"
    FAILED=$((FAILED+1))
  fi
}

log "Smoke test sur $BASE_URL"
check "GET /health" 200 "$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
check "GET /todos" 200 "$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/todos")"
check "POST /todos" 201 "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{"title":"smoke"}' "$BASE_URL/todos")"
check "POST /todos sans titre" 400 "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{}' "$BASE_URL/todos")"

log "----------------------------------------"
log "Resultat : $PASSED passed, $FAILED failed"
if [ "$FAILED" -eq 0 ]; then
  log "SMOKE TEST : PASSED"
  exit 0
else
  log "SMOKE TEST : FAILED"
  exit 1
fi