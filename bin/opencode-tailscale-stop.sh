#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

PID_FILE="${PID_FILE:-$PREFIX/tmp/opencode_tailscale.pid}"
NOTIFY_FILE="${NOTIFY_FILE:-$PREFIX/tmp/opencode_tailscale_url.txt}"
LOG_FILE="${LOG_FILE:-$PREFIX/tmp/opencode_tailscale.log}"

if [ ! -f "$PID_FILE" ]; then
    echo "[INFO] Nao esta rodando (PID file nao encontrado)."
    stty sane 2>/dev/null || true
    termux-wake-unlock 2>/dev/null || true
    exit 0
fi

PID=$(cat "$PID_FILE")
echo "[INFO] Parando servico (PID $PID)..."

# Graceful kill
kill "$PID" 2>/dev/null

for i in 1 2 3; do
    kill -0 "$PID" 2>/dev/null || break
    sleep 1
done

# Force kill if still alive
kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null || true

# Stop tailscale serve
echo "[INFO] Parando tailscale serve..."
tailscale serve --https=off 2>/dev/null || true

# Cleanup files
rm -f "$PID_FILE" "$NOTIFY_FILE" "$LOG_FILE"

stty sane 2>/dev/null || true
termux-wake-unlock 2>/dev/null || true

echo "[INFO] Servico parado."
