#!/bin/sh
LOG_DIR="${LOG_DIR:-/var/log/daemon-monitor}"
LOG_SIZE="${LOG_SIZE:-2000000}"
LOG_KEEP="${LOG_KEEP:-20}"

# Checking if directory for logs exists
mkdir -p "$LOG_DIR" || true

# Better format/rotation (t - human-readable, s - rotation bytes, n - count of old logs)
exec multilog "s${LOG_SIZE}" "n${LOG_KEEP}" '!tai64nlocal' "$LOG_DIR"
