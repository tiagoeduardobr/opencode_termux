#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
    set -a; source .env; set +a
fi

PORT="${OPENCODE_PORT:-4096}"
HOSTNAME="${OPENCODE_HOSTNAME:-127.0.0.1}"
NOTIFY_FILE="${NOTIFY_FILE:-/tmp/opencode_tailscale_url.txt}"
NTFY_TOPIC="${NTFY_TOPIC:-opencode-tunnel}"

cleanup() {
    echo "[INFO] Parando OpenCode Web..."
    [[ -n "${OPENCODE_PID:-}" ]] && kill "$OPENCODE_PID" 2>/dev/null || true
}
trap cleanup EXIT SIGINT SIGTERM

rm -f "$NOTIFY_FILE"

# Kill any process already listening on the port
if command -v lsof >/dev/null 2>&1; then
    if lsof -ti :"$PORT" >/dev/null 2>&1; then
        echo "[INFO] Matando processo anterior na porta $PORT..."
        lsof -ti :"$PORT" | xargs -r kill -9 2>/dev/null || true
    fi
elif command -v fuser >/dev/null 2>&1; then
    if fuser "$PORT"/tcp >/dev/null 2>&1; then
        echo "[INFO] Matando processo anterior na porta $PORT (fuser)..."
        fuser -k "$PORT"/tcp 2>/dev/null || true
    fi
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

echo "[INFO] OpenCode Web rodando (PID $OPENCODE_PID)"
echo "http://${HOSTNAME}:${PORT}" > "$NOTIFY_FILE"
echo "[INFO] Prontidao sinalizada em $NOTIFY_FILE"

wait "$OPENCODE_PID"
