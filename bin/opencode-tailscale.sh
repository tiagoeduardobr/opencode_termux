#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

NOTIFY_FILE="${NOTIFY_FILE:-$PREFIX/tmp/opencode_tailscale_url.txt}"
PID_FILE="${PID_FILE:-$PREFIX/tmp/opencode_tailscale.pid}"
LOG_FILE="${LOG_FILE:-$PREFIX/tmp/opencode_tailscale.log}"
PORT="${OPENCODE_PORT:-4096}"

# Verificar se ja esta rodando
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "[ERROR] Ja esta rodando (PID $(cat "$PID_FILE")). Use opencode_tailscale_stop primeiro."
    exit 1
fi

rm -f "$NOTIFY_FILE" "$PID_FILE" "$LOG_FILE"

# Verificar proot-distro
if ! command -v proot-distro >/dev/null 2>&1; then
    echo "[ERROR] proot-distro não encontrado. Instale com: pkg install proot-distro"
    exit 1
fi

# Verificar tailscale
if ! command -v tailscale >/dev/null 2>&1; then
    echo "[ERROR] tailscale não encontrado. Instale: https://tailscale.com/kb/1016/install/"
    exit 1
fi

# Verificar tailscaled
if ! tailscale status >/dev/null 2>&1; then
    echo "[WARN] tailscaled nao esta rodando. Execute 'tailscale up' primeiro."
fi

# Detectar Tailscale IP
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
if [ -z "$TAILSCALE_IP" ]; then
    echo "[WARN] Nao foi possivel detectar IP Tailscale."
else
    echo "[INFO] Tailscale IP: $TAILSCALE_IP"
fi

# Wake lock
termux-wake-lock 2>/dev/null && echo "[INFO] Wake lock adquirido"

# Iniciar proot
nohup proot-distro login ubuntu --shared-tmp -- bash -c '
  cd "$1" && exec ./run-opencode-tailscale.sh
' _ "$SCRIPT_DIR" </dev/null >"$LOG_FILE" 2>&1 &
PROOT_PID=$!
echo "$PROOT_PID" > "$PID_FILE"
disown "$PROOT_PID" 2>/dev/null || true

# Verificar se proot nao morreu
sleep 2
if ! kill -0 "$PROOT_PID" 2>/dev/null; then
    echo "[ERROR] Proot morreu rapidamente. Ultimas linhas do log:"
    tail -20 "$LOG_FILE" 2>/dev/null || echo "(log vazio ou inacessivel)"
    rm -f "$PID_FILE"
    exit 1
fi

echo "[INFO] Aguardando opencode iniciar (PID proot: $PROOT_PID)..."
URL=""
for i in {1..60}; do
    if [ -f "$NOTIFY_FILE" ]; then
        URL=$(cat "$NOTIFY_FILE" 2>/dev/null)
        [ -n "$URL" ] && break
    fi
    sleep 1
done

# tailscale serve
if [ -n "$TAILSCALE_IP" ] && [ -n "$URL" ]; then
    echo "[INFO] Expondo porta via tailscale serve..."
    # Configurar tailscale serve (HTTP ou HTTPS)
    if [ "${TAILSCALE_SERVE_HTTP:-true}" = "true" ]; then
        if ! tailscale serve --bg --http="$PORT" "$PORT" 2>>"$LOG_FILE"; then
            echo "[WARN] tailscale serve (HTTP) falhou. Consulte: $LOG_FILE"
        fi
    else
        if ! tailscale serve --bg "$PORT" 2>>"$LOG_FILE"; then
            echo "[WARN] tailscale serve (HTTPS) falhou. Consulte: $LOG_FILE"
        fi
    fi

    TAILSCALE_URL="http://${TAILSCALE_IP}:${PORT}"
    echo "[INFO] Tailscale URL: $TAILSCALE_URL"

    # ntfy.sh notification
    echo "[INFO] Enviando notificacao ntfy.sh..."
    timeout 5 curl -s -d "OpenCode Tailscale ativo: $TAILSCALE_URL" "https://ntfy.sh/${NTFY_TOPIC:-opencode-tunnel}" >/dev/null 2>&1 || true

    # termux-notification
    timeout 5 termux-notification \
        --id opencode-tailscale \
        --title "OpenCode Web (Tailscale)" \
        --content "Tailscale: ${TAILSCALE_URL}" \
        --button1 "Abrir" \
        --button1-action "termux-open-url ${TAILSCALE_URL}" \
        --button2 "Copiar" \
        --button2-action "termux-clipboard-set ${TAILSCALE_URL}" \
        --priority high \
        --ongoing 2>/dev/null || true
else
    if [ -z "$TAILSCALE_IP" ]; then
        echo "[WARN] Tailscale IP indisponivel — tailscale serve pulado."
    else
        echo "[WARN] URL do tunnel nao detectada em 60s. Veja o log: $LOG_FILE"
    fi
fi

echo "[INFO] Servico rodando em background (PID $PROOT_PID). Use opencode_tailscale_stop para parar."
