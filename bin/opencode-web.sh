#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

NOTIFY_FILE="${NOTIFY_FILE:-$PREFIX/tmp/opencode_url.txt}"
PID_FILE="${PID_FILE:-$PREFIX/tmp/opencode_web.pid}"
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "[ERROR] Ja esta rodando (PID $(cat "$PID_FILE")). Use opencode_web_stop primeiro."
    exit 1
fi

rm -f "$NOTIFY_FILE" "$PID_FILE"

if ! command -v proot-distro >/dev/null 2>&1; then
    echo "[ERROR] proot-distro não encontrado. Instale com: pkg install proot-distro"
    exit 1
fi

termux-wake-lock 2>/dev/null && echo "[INFO] Wake lock adquirido"

echo "[INFO] Iniciando proot + OpenCode + Cloudflare Tunnel..."
echo "[INFO] Projeto: $PROJECT_DIR"

nohup proot-distro login ubuntu --shared-tmp -- bash -c '
  cd "$1" && ./run-cloudflare-tunnel.sh
' _ "$PROJECT_DIR" </dev/null >/dev/null 2>&1 &
PROOT_PID=$!

echo "$PROOT_PID" > "$PID_FILE"

disown "$PROOT_PID" 2>/dev/null || true

echo "[INFO] Aguardando URL do tunnel (PID proot: $PROOT_PID)..."
URL=""
for i in {1..60}; do
    if [ -f "$NOTIFY_FILE" ]; then
        URL=$(cat "$NOTIFY_FILE" 2>/dev/null)
        [ -n "$URL" ] && break
    fi
    sleep 1
done

if [ -n "$URL" ]; then
    if echo "$URL" | grep -qE '^https://[a-zA-Z0-9_-]+\.trycloudflare\.com$'; then
        echo "[INFO] Tunnel ativo: $URL"
        timeout 5 termux-notification \
            --id opencode-tunnel \
            --title "OpenCode Web" \
            --content "Tunnel ativo: ${URL}" \
            --action "termux-open-url ${URL}" \
            --button1 "Abrir" \
            --button1-action "termux-open-url ${URL}" \
            --button2 "Copiar" \
            --button2-action "termux-clipboard-set ${URL}" \
            --priority high \
            --ongoing 2>/dev/null || true
    else
        echo "[ERROR] URL malformada: $URL"
    fi
else
    echo "[WARN] URL nao detectada em 60s. Verifique o cloudflared."
fi

echo "[INFO] Servico rodando em background (PID $PROOT_PID). Use opencode_web_stop para parar."
