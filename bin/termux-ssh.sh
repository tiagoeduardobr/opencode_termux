#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

NTFY_TOPIC="${NTFY_TOPIC:-opencode-tunnel}"
SSH_PORT="${SSH_PORT:-8022}"
SSHD_PID_FILE="${SSHD_PID_FILE:-$PREFIX/tmp/termux_sshd.pid}"

if ! command -v sshd >/dev/null 2>&1; then
    echo "[ERROR] openssh nao encontrado. Instale com: pkg install openssh"
    exit 1
fi

if [ -f "$SSHD_PID_FILE" ] && kill -0 "$(cat "$SSHD_PID_FILE")" 2>/dev/null; then
    echo "[INFO] sshd ja esta rodando (PID $(cat "$SSHD_PID_FILE"))."
else
    echo "[INFO] Iniciando sshd na porta $SSH_PORT..."
    sshd
    echo $! > "$SSHD_PID_FILE"
    echo "[INFO] sshd iniciado (PID $!)."
fi

DEVICE_IP=$(ip addr show 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1)
if [ -z "$DEVICE_IP" ]; then
    echo "[ERROR] Nao foi possivel detectar IP do dispositivo."
    exit 1
fi

SSH_COMMAND="ssh root@${DEVICE_IP} -p ${SSH_PORT}"
echo "[INFO] Comando SSH: $SSH_COMMAND"

echo "[INFO] Enviando notificacao ntfy.sh..."
curl -s \
    -H "Title: Termux SSH" \
    -H "Actions: copy, Copiar comando, ${SSH_COMMAND}" \
    -d "sshd ativo em ${DEVICE_IP}:${SSH_PORT}" \
    "https://ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 || true

echo "[INFO] Enviando notificacao local..."
timeout 5 termux-notification \
    --id termux-ssh \
    --title "Termux SSH" \
    --content "sshd ativo em ${DEVICE_IP}:${SSH_PORT}" \
    --button1 "Copiar" \
    --button1-action "termux-clipboard-set ${SSH_COMMAND}" \
    --button2 "Parar" \
    --button2-action "bash ${SCRIPT_DIR}/bin/termux-ssh-stop.sh" \
    --priority high \
    --ongoing 2>/dev/null || true

echo "[OK] sshd ativo. Conecte com: $SSH_COMMAND"
