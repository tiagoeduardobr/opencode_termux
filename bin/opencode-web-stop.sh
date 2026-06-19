#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

PID_FILE="${PID_FILE:-$PREFIX/tmp/opencode_web.pid}"
NOTIFY_FILE="${NOTIFY_FILE:-$PREFIX/tmp/opencode_url.txt}"
LOG_FILE="${LOG_FILE:-$PREFIX/tmp/opencode_web.log}"

if [ ! -f "$PID_FILE" ]; then
    echo "[INFO] Nao esta rodando (PID file nao encontrado)."
    stty sane 2>/dev/null || true
    termux-wake-unlock 2>/dev/null || true
    exit 0
fi

PID=$(cat "$PID_FILE")
echo "[INFO] Parando servico (PID $PID)..."

kill "$PID" 2>/dev/null

for i in 1 2 3; do
    kill -0 "$PID" 2>/dev/null || break
    sleep 1
done

kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null || true

rm -f "$PID_FILE" "$NOTIFY_FILE" "$LOG_FILE"

stty sane 2>/dev/null || true
termux-wake-unlock 2>/dev/null || true

echo "[INFO] Servico parado."
