#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_TARGET="$SCRIPT_DIR/.config/opencode"
CONFIG_LINK="$HOME/.config/opencode"

echo "========================================"
echo " opencode_termux — Setup"
echo "========================================"
echo ""

# ── 1. Global opencode config symlink ──────────────────────────────────
if [ -e "$CONFIG_LINK" ] || [ -L "$CONFIG_LINK" ]; then
    if [ -L "$CONFIG_LINK" ] && [ "$(readlink "$CONFIG_LINK")" = "$CONFIG_TARGET" ]; then
        echo "[OK] Symlink ja aponta para $CONFIG_TARGET"
    else
        BAK="${CONFIG_LINK}.bak.$(date +%Y%m%d%H%M%S)"
        echo "[INFO] Fazendo backup de $CONFIG_LINK → $BAK"
        mv "$CONFIG_LINK" "$BAK"
        echo "[INFO] Criando symlink: $CONFIG_LINK → $CONFIG_TARGET"
        ln -s "$CONFIG_TARGET" "$CONFIG_LINK"
    fi
else
    echo "[INFO] Criando $CONFIG_LINK..."
    mkdir -p "$HOME/.config"
    echo "[INFO] Criando symlink: $CONFIG_LINK → $CONFIG_TARGET"
    ln -s "$CONFIG_TARGET" "$CONFIG_LINK"
fi

echo ""

# ── 2. npm install ────────────────────────────────────────────────────
if [ -f "$CONFIG_TARGET/package.json" ]; then
    echo "[INFO] Instalando dependencias npm..."
    cd "$CONFIG_TARGET" && npm install --quiet 2>/dev/null || true
    echo "[OK] Dependencias instaladas"
fi

echo ""

# ── 3. Aliases ─────────────────────────────────────────────────────────
ALIAS_LINE="source \"$SCRIPT_DIR/shell/aliases.sh\""
BASHRC="$HOME/.bashrc"

if [ -f "$BASHRC" ] && grep -qF "$ALIAS_LINE" "$BASHRC" 2>/dev/null; then
    echo "[OK] Aliases ja configurados em $BASHRC"
else
    echo "[INFO] Adicionando alias ao $BASHRC..."
    echo "$ALIAS_LINE" >> "$BASHRC"
    echo "[OK] Alias adicionado"
fi

echo ""
echo "========================================"
echo " Setup concluido!"
echo "========================================"
echo ""
echo "Proximo passo:"
echo "  1. source shell/aliases.sh  (ou recarregue o .bashrc)"
echo "  2. cp .env.example .env  (e edite se necessario)"
echo "  3. Reinicie o opencode para aplicar as mudancas"
echo ""

if command -v opencode &>/dev/null; then
    echo "Versao opencode detectada: $(opencode --version 2>/dev/null || echo '?')"
fi
