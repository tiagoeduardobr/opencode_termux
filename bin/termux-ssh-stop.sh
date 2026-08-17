#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

SSHD_PID_FILE="${SSHD_PID_FILE:-$PREFIX/tmp/termux_sshd.pid}"

if [ ! -f "$SSHD_PID_FILE" ]; then
    echo "[INFO] sshd nao esta rodando."
    exit 0
fi

PID=$(cat "$SSHD_PID_FILE")

if [ -z "$PID" ]; then
    echo "[WARN] PID file vazio. Limpando..."
    rm -f "$SSHD_PID_FILE"
    exit 0
fi

echo "[INFO] Parando sshd (PID $PID)..."

kill "$PID" 2>/dev/null

for i in 1 2 3; do
    kill -0 "$PID" 2>/dev/null || break
    sleep 1
done

kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null || true

rm -f "$SSHD_PID_FILE"

# Notificação limpa automaticamente pelo Android (id + ongoing)

stty sane 2>/dev/null || true

echo "[INFO] sshd parado."
