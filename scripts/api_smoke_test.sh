#!/usr/bin/env bash
set -euo pipefail

# Read-only smoke test for Emby Pulse APIs used by the iOS app.
# Usage:
#   BASE_URL=http://127.0.0.1:10307 ADMIN_USER=admin ADMIN_PASS=pass \
#   ./scripts/api_smoke_test.sh
#
# Optional:
#   RUN_MUTATING=1 INVITE_CODE=xxx REG_USER=foo REG_PASS=bar ./scripts/api_smoke_test.sh

BASE_URL="${BASE_URL:-}"
ADMIN_USER="${ADMIN_USER:-}"
ADMIN_PASS="${ADMIN_PASS:-}"
RUN_MUTATING="${RUN_MUTATING:-0}"

if [[ -z "$BASE_URL" || -z "$ADMIN_USER" || -z "$ADMIN_PASS" ]]; then
  echo "Missing required env: BASE_URL / ADMIN_USER / ADMIN_PASS"
  exit 1
fi

BASE_URL="${BASE_URL%/}"
COOKIE_JAR="$(mktemp)"
trap 'rm -f "$COOKIE_JAR"' EXIT

PASS_COUNT=0
FAIL_COUNT=0

run_case() {
  local name="$1"
  local method="$2"
  local path="$3"
  local body="${4:-}"

  local url="${BASE_URL}${path}"
  local resp

  if [[ "$method" == "GET" ]]; then
    resp="$(curl -sS -m 20 -b "$COOKIE_JAR" -c "$COOKIE_JAR" "$url" || true)"
  else
    resp="$(curl -sS -m 20 -X "$method" -H 'Content-Type: application/json' \
      -b "$COOKIE_JAR" -c "$COOKIE_JAR" -d "$body" "$url" || true)"
  fi

  if echo "$resp" | grep -q '"status"[[:space:]]*:[[:space:]]*"success"'; then
    echo "[PASS] $name"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "[FAIL] $name"
    echo "  URL: $url"
    echo "  RESP: ${resp:0:220}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "== Login =="
run_case "login" "POST" "/api/login" "{\"username\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}"

echo "== Core =="
run_case "dashboard" "GET" "/api/stats/dashboard"
run_case "live sessions" "GET" "/api/stats/live"
run_case "users" "GET" "/api/users"
run_case "history list" "GET" "/api/history/list?page=1&limit=10&user_id=all&keyword="
run_case "trend day" "GET" "/api/stats/trend?user_id=all&dimension=day"

echo "== Calendar =="
run_case "calendar weekly" "GET" "/api/calendar/weekly?offset=0&refresh=false"

echo "== Requests admin =="
run_case "managed requests" "GET" "/api/manage/requests"

echo "== Feedback admin =="
run_case "managed feedback" "GET" "/api/manage/feedback"

echo "== User management =="
run_case "managed users" "GET" "/api/manage/users"
run_case "invites list" "GET" "/api/manage/invites"

echo "== Utilities =="
run_case "top movies" "GET" "/api/stats/top_movies?user_id=all&category=all&sort_by=count"
run_case "top users list" "GET" "/api/stats/top_users_list?period=week"
run_case "badges" "GET" "/api/stats/badges?user_id=all"
run_case "user details" "GET" "/api/stats/user_details?user_id=all"
run_case "monthly stats" "GET" "/api/stats/monthly_stats?user_id=all"
run_case "recent activity" "GET" "/api/stats/recent?user_id=all"
run_case "latest media" "GET" "/api/stats/latest?limit=10"
run_case "libraries" "GET" "/api/stats/libraries"
run_case "insight quality" "GET" "/api/insight/quality?force_refresh=false"
run_case "insight ignores" "GET" "/api/insight/ignores"
run_case "client blacklist" "GET" "/api/clients/blacklist"
run_case "client data" "GET" "/api/clients/data"
run_case "bot settings" "GET" "/api/bot/settings"
run_case "system settings" "GET" "/api/settings"
run_case "tasks" "GET" "/api/tasks"
run_case "poster data" "GET" "/api/stats/poster_data?user_id=all&period=month"

if [[ "$RUN_MUTATING" == "1" ]]; then
  echo "== Mutating (optional) =="
  run_case "calendar config ttl" "POST" "/api/calendar/config" '{"ttl":86400}'
  run_case "batch request no-op" "POST" "/api/manage/requests/batch" '{"items":[],"action":"delete"}'

  INVITE_CODE="${INVITE_CODE:-}"
  REG_USER="${REG_USER:-}"
  REG_PASS="${REG_PASS:-}"
  if [[ -n "$INVITE_CODE" && -n "$REG_USER" && -n "$REG_PASS" ]]; then
    run_case "register invite" "POST" "/api/register" "{\"code\":\"${INVITE_CODE}\",\"username\":\"${REG_USER}\",\"password\":\"${REG_PASS}\"}"
  else
    echo "[SKIP] register invite (need INVITE_CODE / REG_USER / REG_PASS)"
  fi
fi

echo
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 2
fi

