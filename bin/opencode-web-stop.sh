#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

PID_FILE="${PID_FILE:-$PREFIX/tmp/opencode_web.pid}"
NOTIFY_FILE="${NOTIFY_FILE:-$PREFIX/tmp/opencode_url.txt}"
LOG_FILE="${LOG_FILE:-$PREFIX/tmp/opencode_web.log}"
PORT="${OPENCODE_PORT:-4096}"
HOSTNAME="${OPENCODE_HOSTNAME:-127.0.0.1}"
TOOLS_WARNED=0

is_zombie() {
    local pid="$1" stat
    stat=$(ps -o stat= -p "$pid" 2>/dev/null | tr -d ' ')
    case "$stat" in
        Z*) return 0 ;;
        *)  return 1 ;;
    esac
}

kill_graceful() {
    local pid="$1"
    kill "$pid" 2>/dev/null
    for _ in 1 2 3; do
        kill -0 "$pid" 2>/dev/null || return 0
        if is_zombie "$pid"; then
            echo "[INFO] PID $pid virou zumbi; sera reaped pelo init."
            return 0
        fi
        sleep 1
    done
    if kill -0 "$pid" 2>/dev/null && ! is_zombie "$pid"; then
        kill -9 "$pid" 2>/dev/null || true
    fi
}

port_pids() {
    local pids="" missing=""
    if ! command -v lsof >/dev/null 2>&1 && ! command -v fuser >/dev/null 2>&1; then
        missing="lsof/fuser"
    elif ! command -v lsof >/dev/null 2>&1; then
        missing="lsof"
    elif ! command -v fuser >/dev/null 2>&1; then
        missing="fuser"
    fi
    if [ -n "$missing" ] && [ "$TOOLS_WARNED" = "0" ]; then
        echo "[WARN] ${missing} indisponivel; limpeza por porta limitada." >&2
        TOOLS_WARNED=1
    fi
    if command -v lsof >/dev/null 2>&1; then
        pids=$(lsof -ti :"$PORT" 2>/dev/null || true)
    fi
    if [ -z "$pids" ] && command -v fuser >/dev/null 2>&1; then
        pids=$(fuser -n tcp "$PORT" 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9]+$' || true)
    fi
    if [ -z "$pids" ]; then
        echo ""
    else
        echo "$pids"
    fi
}

PID=""
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE" 2>/dev/null || true)
fi

if [ -z "$PID" ]; then
    echo "[INFO] Nao esta rodando (PID file nao encontrado). Tentando limpar orfaos..."
else
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "[WARN] PID $PID nao esta rodando."
    elif is_zombie "$PID"; then
        echo "[WARN] PID $PID e um processo zumbi; nao pode ser morto; sera reaped pelo init."
    else
        echo "[INFO] Parando servico (PID $PID)..."
        kill_graceful "$PID"
    fi
fi

SCRIPT_PATTERN='run-cloudflare-tunnel.sh'
CLOUDFLARED_PATTERN="cloudflared tunnel --url http://127.0.0.1:${PORT}"

echo "[INFO] Limpando processos orfaos..."

# Fase A (SIGTERM)
pkill -TERM -f "$SCRIPT_PATTERN" 2>/dev/null || true
pkill -TERM -f "$CLOUDFLARED_PATTERN" 2>/dev/null || true
if [ -n "$(port_pids)" ]; then
    kill $(port_pids) 2>/dev/null || true
fi

# Espera (até 3x1s enquanto houver alvo vivo não-zumbi)
for _ in 1 2 3; do
    alive=0
    for p in $( (pgrep -f "$SCRIPT_PATTERN" 2>/dev/null; pgrep -f "$CLOUDFLARED_PATTERN" 2>/dev/null; port_pids) | sort -n | uniq ); do
        if ! is_zombie "$p"; then
            alive=1
            break
        fi
    done
    [ "$alive" = "0" ] && break
    sleep 1
done

# Fase B (SIGKILL)
pkill -9 -f "$SCRIPT_PATTERN" 2>/dev/null || true
pkill -9 -f "$CLOUDFLARED_PATTERN" 2>/dev/null || true
if [ -n "$(port_pids)" ]; then
    kill -9 $(port_pids) 2>/dev/null || true
fi

# Verificacao final
remaining_alive=0
for p in $( (pgrep -f "$SCRIPT_PATTERN" 2>/dev/null; pgrep -f "$CLOUDFLARED_PATTERN" 2>/dev/null; port_pids) | sort -n | uniq ); do
    if is_zombie "$p"; then
        echo "[INFO] Zumbi PID $p sera reaped pelo init."
    else
        echo "[WARN] Processo remanescente: $(ps -o pid=,args= -p "$p" 2>/dev/null | tr -s ' ')"
        remaining_alive=1
    fi
done

if [ "$remaining_alive" = "1" ]; then
    echo "[WARN] Ha processos remanescentes. Verifique manualmente."
else
    echo "[INFO] Nenhum processo remanescente."
fi

rm -f "$PID_FILE" "$NOTIFY_FILE" "$LOG_FILE"

stty sane 2>/dev/null || true
termux-wake-unlock 2>/dev/null || true

echo "[INFO] Servico parado."
