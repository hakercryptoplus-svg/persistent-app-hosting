#!/bin/bash

# Watchdog Script — مراقب العمليات
# يراقب عملية معينة ويعيد تشغيلها عند التوقف
# الاستخدام: bash watchdog.sh <session_name> "<command>" [workdir]

set -euo pipefail

SESSION_NAME="${1:-myapp}"
COMMAND="${2:-echo 'No command specified'}"
WORKDIR="${3:-$HOME}"
CHECK_INTERVAL="${4:-30}"
LOG_FILE="${HOME}/.watchdog-${SESSION_NAME}.log"
MAX_RESTARTS=10
RESTART_COUNT=0
RESTART_WINDOW=3600  # reset counter after 1 hour
LAST_RESET=$(date +%s)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_tmux() {
    if ! command -v tmux &>/dev/null; then
        log "${RED}[ERROR]${NC} tmux غير مثبت. جرب: sudo apt install tmux"
        exit 1
    fi
}

start_session() {
    log "${GREEN}[START]${NC} بدء جلسة tmux: ${SESSION_NAME}"
    tmux new-session -d -s "$SESSION_NAME" -c "$WORKDIR" "$COMMAND" 2>/dev/null || true
}

is_running() {
    tmux has-session -t "$SESSION_NAME" 2>/dev/null
}

restart_session() {
    local now=$(date +%s)
    local elapsed=$((now - LAST_RESET))

    # Reset counter after window
    if [ "$elapsed" -gt "$RESTART_WINDOW" ]; then
        RESTART_COUNT=0
        LAST_RESET=$now
    fi

    RESTART_COUNT=$((RESTART_COUNT + 1))

    if [ "$RESTART_COUNT" -gt "$MAX_RESTARTS" ]; then
        log "${RED}[FATAL]${NC} تجاوز الحد الأقصى لإعادة التشغيل ($MAX_RESTARTS) خلال ${RESTART_WINDOW}s. توقف."
        exit 1
    fi

    log "${YELLOW}[RESTART]${NC} إعادة تشغيل ($RESTART_COUNT/$MAX_RESTARTS)..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    sleep 2
    start_session
}

# --- Main ---
check_tmux

log "=========================================="
log "Watchdog بدأ"
log "Session: $SESSION_NAME"
log "Command: $COMMAND"
log "Workdir: $WORKDIR"
log "Interval: ${CHECK_INTERVAL}s"
log "=========================================="

# Start if not running
if ! is_running; then
    start_session
fi

# Watchdog loop
while true; do
    sleep "$CHECK_INTERVAL"

    if is_running; then
        log "${GREEN}[OK]${NC} $SESSION_NAME يعمل"
    else
        log "${RED}[DOWN]${NC} $SESSION_NAME توقف!"
        restart_session
    fi
done
