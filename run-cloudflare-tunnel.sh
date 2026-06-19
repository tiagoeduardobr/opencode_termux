#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
    set -a; source .env; set +a
fi

PORT="${OPENCODE_PORT:-4096}"
HOSTNAME="${OPENCODE_HOSTNAME:-127.0.0.1}"
NOTIFY_FILE="${NOTIFY_FILE:-/tmp/opencode_url.txt}"
NTFY_TOPIC="${NTFY_TOPIC:-opencode-tunnel}"
CLOUDFLARED_LOG="/tmp/cloudflared_tunnel.log"

cleanup() {
    echo "[INFO] Parando OpenCode e Cloudflare Tunnel..."
    [[ -n "${OPENCODE_PID:-}" ]] && kill "$OPENCODE_PID" 2>/dev/null || true
    [[ -n "${CLOUDFLARED_PID:-}" ]] && kill "$CLOUDFLARED_PID" 2>/dev/null || true
    rm -f "$CLOUDFLARED_LOG"
}
trap cleanup EXIT SIGINT SIGTERM

rm -f "$NOTIFY_FILE"

# Kill any process already listening on the port (best-effort)
if command -v lsof >/dev/null 2>&1; then
    if lsof -ti :"$PORT" >/dev/null 2>&1; then
        echo "[INFO] Matando processo anterior na porta $PORT..."
        lsof -ti :"$PORT" | xargs -r kill -9 2>/dev/null || true
    fi
else
    echo "[WARN] lsof nao instalado — não foi possivel matar processo anterior na porta $PORT"
fi

# Ensure opencode CLI is available
if ! command -v opencode >/dev/null 2>&1; then
    echo "[ERROR] opencode nao encontrado no PATH. Instale com: npm install -g opencode-ai"
    exit 1
fi

echo "[INFO] Iniciando OpenCode Web em http://${HOSTNAME}:${PORT}"
opencode web --hostname "$HOSTNAME" --port "$PORT" &
OPENCODE_PID=$!
sleep 3

if ! kill -0 "$OPENCODE_PID" 2>/dev/null; then
    echo "[ERROR] OpenCode web falhou ao iniciar."
    exit 1
fi

if ! command -v cloudflared >/dev/null 2>&1; then
    echo "[ERROR] cloudflared nao encontrado no PATH."
    exit 1
fi

echo "[INFO] Iniciando Cloudflare Tunnel..."
cloudflared tunnel --url "http://127.0.0.1:${PORT}" >"$CLOUDFLARED_LOG" 2>&1 &
CLOUDFLARED_PID=$!

for i in {1..45}; do
    URL=$(grep -oE 'https://[a-zA-Z0-9_-]+\.trycloudflare\.com' "$CLOUDFLARED_LOG" 2>/dev/null || true)
    if [ -n "$URL" ]; then
        echo "$URL" > "$NOTIFY_FILE"
        echo "[INFO] URL publica: $URL"
        echo "[INFO] Enviando notificacao ntfy.sh..."
        curl -s -d "Tunnel ativo: $URL" "https://ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 || true
        break
    fi
    sleep 1
done

wait "$CLOUDFLARED_PID"
