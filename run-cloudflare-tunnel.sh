#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
    set -a; source .env; set +a
fi

PORT="${OPENCODE_PORT:-4096}"
NOTIFY_FILE="${NOTIFY_FILE:-/tmp/opencode_url.txt}"
NTFY_TOPIC="${NTFY_TOPIC:-opencode-tunnel}"

cleanup() {
    echo "[INFO] Parando OpenCode e Cloudflare Tunnel..."
    [[ -n "${OPENCODE_PID:-}" ]] && kill "$OPENCODE_PID" 2>/dev/null || true
    [[ -n "${CLOUDFLARED_PID:-}" ]] && kill "$CLOUDFLARED_PID" 2>/dev/null || true
    rm -f "${CLOUDFLARED_LOG:-}"
}
trap cleanup EXIT SIGINT SIGTERM

rm -f "$NOTIFY_FILE"

echo "[INFO] Iniciando OpenCode Web em http://127.0.0.1:${PORT}"
opencode web --hostname 127.0.0.1 --port "${PORT}" &
OPENCODE_PID=$!
sleep 3

if ! kill -0 "$OPENCODE_PID" 2>/dev/null; then
    echo "[ERROR] OpenCode web falhou ao iniciar."
    cleanup
    exit 1
fi

if ! command -v cloudflared >/dev/null 2>&1; then
    echo "[ERROR] cloudflared não encontrado no PATH."
    cleanup
    exit 1
fi

CLOUDFLARED_LOG=$(mktemp)
echo "[INFO] Iniciando Cloudflare Tunnel..."
cloudflared tunnel --url "http://127.0.0.1:${PORT}" >"$CLOUDFLARED_LOG" 2>&1 &
CLOUDFLARED_PID=$!

for i in {1..45}; do
    URL=$(grep -oE 'https://[a-zA-Z0-9_-]+\.trycloudflare\.com' "$CLOUDFLARED_LOG" 2>/dev/null || true)
    if [ -n "$URL" ]; then
        echo "$URL" > "$NOTIFY_FILE"
        echo "[INFO] URL pública: $URL"
        echo "[INFO] Enviando notificação ntfy.sh..."
        curl -s -d "Tunnel ativo: $URL" "https://ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 || true
        break
    fi
    sleep 1
done

wait "$CLOUDFLARED_PID"
