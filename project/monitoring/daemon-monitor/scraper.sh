#!/bin/sh

# Multilog will capture everything
exec 2>&1

PROM_URL="${PROM_URL:-http://prometheus:9090}"
PROM_QUERY="${PROM_QUERY:-avg(node_load1)}"
NGINX_STUB="${NGINX_STUB:-https://proxy/stub_status}"
INTERVAL="${INTERVAL:-15}"
TIMEOUT="${TIMEOUT:-5}"

# --- CockroachDB test config ---
CRDB_DSN="${CRDB_DSN:-postgresql://root@crdb1:26257?sslmode=disable}"
CRDB_DB="${CRDB_DB:-monitor}"
CRDB_TABLE="${CRDB_TABLE:-heartbeat}"
CRDB_WRITE_TEST="${CRDB_WRITE_TEST:-true}"
CRDB_NODES="crdb1:8091 crdb2:8092 crdb3:8093 crdb4:8094 crdb5:8095"

echo "Daemon-monitor starting: PROM_URL=${PROM_URL} QUERY=${PROM_QUERY} NGINX=${NGINX_STUB} INTERVAL=${INTERVAL}s TIMEOUT=${TIMEOUT}s"
echo "CRDB: DSN=${CRDB_DSN} DB=${CRDB_DB} TABLE=${CRDB_TABLE} WRITE_TEST=${CRDB_WRITE_TEST}"


psql_exec() {
  psql "${CRDB_DSN}" -v ON_ERROR_STOP=1 -At -c "$1"
}

# One-time init (best-effort; safe if already exists)
#crdb_init() {
#  psql_exec "SET statement_timeout='5s'; CREATE DATABASE IF NOT EXISTS ${CRDB_DB};" || true
#  psql_exec "SET statement_timeout='5s'; \
#    CREATE TABLE IF NOT EXISTS ${CRDB_DB}.${CRDB_TABLE} ( \
#      ts TIMESTAMPTZ DEFAULT now(), \
#      note STRING, \
#      id UUID DEFAULT gen_random_uuid(), \
#      PRIMARY KEY (ts, id) \
#    );" || true
#}
#crdb_init

while :; do
  # --- Timestamp for your human block (multilog can add its own too) ---
  ts="$(date '+%Y-%m-%d %H:%M:%S')"

  # --- Prometheus ---
  prom_value="$(curl -sfG --max-time "$TIMEOUT" \
              --data-urlencode "query=$PROM_QUERY" \
              "$PROM_URL/api/v1/query" \
              | jq -r '.data.result[0].value[1]' 2>/dev/null || echo NA)"

  # --- NGINX stub_status (parse) ---
  stub="$(curl -k -sf --max-time "$TIMEOUT" "$NGINX_STUB" || echo NA)"
  active=NA accepts=NA handled=NA requests=NA reading=NA writing=NA waiting=NA
  if [ "$stub" != "NA" ]; then
    active=$(echo "$stub"   | awk '/Active connections/ {print $3}')
    accepts=$(echo "$stub"  | awk 'NR==3 {print $1}')
    handled=$(echo "$stub"  | awk 'NR==3 {print $2}')
    requests=$(echo "$stub" | awk 'NR==3 {print $3}')
    reading=$(echo "$stub"  | awk '/Reading/ {print $2}')
    writing=$(echo "$stub"  | awk '/Writing/ {print $4}')
    waiting=$(echo "$stub"  | awk '/Waiting/ {print $6}')
  fi

  echo "$ts"
  echo "Load average: $prom_value"
  echo "Active connections: $active"
  echo "Requests: $requests"
  echo "Reading: $reading  Writing: $writing  Waiting: $waiting"

  # --- CockroachDB health + write/read test ---
  for np in $CRDB_NODES; do
    name="${np%%:*}"
    port="${np##*:}"
    base="http://${name}:${port}"
    code="$(curl -sf -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" "$base/health?ready=1" || echo 000)"

    if [ "$code" = "200" ]; then
      echo "CRDB ${name} OK (HTTP 200)"
    else
      echo "CRDB ${name} NOT OK (HTTP ${code})"
    fi
  done

  if [ "$CRDB_WRITE_TEST" = "true" ]; then
    # Insert one heartbeat row and fetch recent count
    insert_out="$(psql_exec "SET statement_timeout='5s'; \
      INSERT INTO ${CRDB_DB}.${CRDB_TABLE} (note) VALUES ('daemon-monitor') RETURNING id;" 2>&1)"
    if [ $? -eq 0 ] && [ -n "$insert_out" ]; then
      hb_id="$(echo "$insert_out" | tail -n1)"
      recent_cnt="$(psql_exec "SET statement_timeout='5s'; \
        SELECT count(*) FROM ${CRDB_DB}.${CRDB_TABLE} WHERE ts > now() - INTERVAL '1 hour';" 2>/dev/null || echo NA)"
      echo "CRDB write: OK id=${hb_id} recent_rows_1h=${recent_cnt}"
    else
      # Print trimmed error (first line is enough for logs)
      err="$(echo "$insert_out" | head -n1)"
      echo "CRDB write: FAIL error=${err}"
    fi
  fi

  echo "---"

  # Optional compact line (keep if you still want it)
##  stub_raw="$(printf "%s" "$stub" | tr '\n' '|' || echo NA)"
#  echo "prom_value=${prom_value} nginx_stub_status=\"${stub_raw}\""

  sleep "$INTERVAL"
done
