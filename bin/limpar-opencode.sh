#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# limpar-opencode.sh — Limpeza manual do DB/cache do OpenCode
#
# Baseado em: .opencode/plans/20260916_0516_limpar-db-opencode.md
# Tasks cobertas: 3 (WAL checkpoint), 4 (events), 5 (sessions),
#                 6 (VACUUM), 7 (log), 8 (tool-output), 9 (cache),
#                 10 (snapshots, opcional), 11 (verificação final)
#
# Tasks 1-2 (pre-flight + backup) já executadas manualmente.
# Backup verificado em ~/opencode-backup-20260916/opencode.db.backup (3.5 GB).
#
# PROTEÇÕES (whitelist — NUNCA tocar):
#   - ~/.config/opencode/            (repo versionado)
#   - auth.json, account.json        (credenciais)
#   - ~/.cache/opencode/bin/         (binário ripgrep)
#   - ~/.cache/opencode/packages/    (plugins)
#   - /tmp/opencode/                 (tmp compartilhado do proot)
# =============================================================================

# --- Cores e funções de output ------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERRO]${NC}  $*"; }
step()  { echo -e "\n${BOLD}━━━ Task $* ━━━${NC}"; }

# --- Configuração -------------------------------------------------------------

BACKUP_DIR="$HOME/opencode-backup-20260916"
BACKUP_FILE="$BACKUP_DIR/opencode.db.backup"
OC_DATA="$HOME/.local/share/opencode"
OC_CACHE="$HOME/.cache/opencode"
OC_DB="$OC_DATA/opencode.db"
WAL_FILE="$OC_DATA/opencode.db-wal"
LOG_FILE="$OC_DATA/log/opencode.log"
TO_DIR="$OC_DATA/tool-output"
SNAP_DIR="$OC_DATA/snapshot"

# Snapshots: default NÃO limpa (definir LIMPAR_SNAPSHOTS=1 antes de executar)
LIMPAR_SNAPSHOTS="${LIMPAR_SNAPSHOTS:-0}"

# Tamanhos antes da limpeza (capturados no início)
TAM_DATA_ANTES=""
TAM_CACHE_ANTES=""

# Contador de falhas (DELETEs com lock, etc.)
FAILURES=0

# =============================================================================
# PRÉ-REQUISITOS
# =============================================================================

# 0. Verificar se opencode está rodando
info "Verificando processos do OpenCode..."

OPENCODE_PIDS=$(pgrep -x opencode 2>/dev/null || true)

if [ -n "$OPENCODE_PIDS" ]; then
    warn "═══════════════════════════════════════════════════════════════"
    warn "  OpenCode ESTÁ RODANDO (PIDs: $OPENCODE_PIDS)"
    warn ""
    warn "  Com o opencode rodando:"
    warn "  • VACUUM pode falhar com 'database is locked'"
    warn "  • O servidor pode recriar dados (sessions/events) durante a limpeza"
    warn "  • Logs podem ser escritos enquanto você limpa"
    warn ""
    warn "  Recomendação: pare o opencode ANTES de executar este script."
    warn "  (Execute fora do web UI, via terminal direto no proot)"
    warn "═══════════════════════════════════════════════════════════════"
    echo ""
    read -p "Continuar mesmo assim? (s/N) " -r
    if [[ ! "$REPLY" =~ ^[sS]$ ]]; then
        info "Abortado pelo usuário."
        exit 0
    fi
    warn "Prosseguindo com opencode rodando — riscos aceitos."
else
    ok "Nenhum processo OpenCode detectado."
fi

# 1. Verificar backup (gate obrigatório — nunca deletar sem backup)
info "Verificando backup de segurança..."

if [ ! -f "$BACKUP_FILE" ]; then
    err "═══════════════════════════════════════════════════════════════"
    err "  BACKUP NÃO ENCONTRADO: $BACKUP_FILE"
    err ""
    err "  ABORTANDO — sem backup, NÃO é seguro deletar dados."
    err "  Execute o backup primeiro:"
    err "    opencode db \"VACUUM INTO '$BACKUP_FILE';\""
    err "═══════════════════════════════════════════════════════════════"
    exit 1
fi

BACKUP_SIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || echo "0")
BACKUP_SIZE_GB=$(awk "BEGIN {printf \"%.2f\", $BACKUP_SIZE / 1073741824}")

if [ "$BACKUP_SIZE" -lt 1073741824 ]; then
    err "═══════════════════════════════════════════════════════════════"
    err "  BACKUP MUITO PEQUENO: ${BACKUP_SIZE_GB} GB ($BACKUP_FILE)"
    err "  Esperado > 1 GB. Backup provavelmente incompleto."
    err ""
    err "  ABORTANDO — refaça o backup antes de continuar."
    err "═══════════════════════════════════════════════════════════════"
    exit 1
fi

ok "Backup verificado: $BACKUP_FILE (${BACKUP_SIZE_GB} GB)"

# 2. Capturar tamanhos antes da limpeza
info "Medindo tamanhos antes da limpeza..."
TAM_DATA_ANTES=$(du -sh "$OC_DATA" 2>/dev/null | cut -f1 || echo "?")
TAM_CACHE_ANTES=$(du -sh "$OC_CACHE" 2>/dev/null | cut -f1 || echo "?")
echo "  ~/.local/share/opencode/ = $TAM_DATA_ANTES"
echo "  ~/.cache/opencode/       = $TAM_CACHE_ANTES"

echo ""
read -p "Pressione ENTER para iniciar a limpeza..." -r

# =============================================================================
# TASK 3: Checkpoint WAL (consolidar ~264 MB)
# =============================================================================

step "3 — Checkpoint WAL (TRUNCATE)"

WAL_SIZE_BEFORE=""
if [ -f "$WAL_FILE" ]; then
    WAL_SIZE_BEFORE=$(du -sh "$WAL_FILE" 2>/dev/null | cut -f1 || echo "?")
    info "Tamanho do WAL antes: $WAL_SIZE_BEFORE"
fi

info "Executando PRAGMA wal_checkpoint(TRUNCATE)..."
CKPT_RESULT=$(opencode db "PRAGMA wal_checkpoint(TRUNCATE);" 2>&1) || true
CKPT_BUSY=$(echo "$CKPT_RESULT" | tail -n 1 | cut -f1)
if [ "$CKPT_BUSY" != "0" ]; then
    warn "Checkpoint parcialmente falhou (busy=$CKPT_BUSY). WAL pode não ter sido truncado."
fi
info "Resultado: $CKPT_RESULT"

if [ -f "$WAL_FILE" ]; then
    WAL_SIZE_AFTER=$(du -sh "$WAL_FILE" 2>/dev/null | cut -f1 || echo "?")
    ok "WAL depois: $WAL_SIZE_AFTER"
else
    ok "WAL truncado (arquivo removido)."
fi

# =============================================================================
# TASK 4: Deletar eventos de replay (~3.1 GB)
# =============================================================================

step "4 — Deletar eventos de replay"

# Ordem importa: 'event' referencia 'event_sequence' via FK.
# Deletar 'event' primeiro (filho), depois 'event_sequence' (pai).

info "Deletando da tabela 'event' (~274.866 linhas)..."
if DELETE_OUT=$(opencode db "DELETE FROM event;" 2>&1); then
    ok "event deletada."
elif [[ "$DELETE_OUT" == *"locked"* ]]; then
    err "  DELETE falhou — database is locked (opencode rodando)."
    err "  Pare o opencode e re-execute."
    FAILURES=$((FAILURES + 1))
else
    err "  DELETE falhou inesperadamente: $DELETE_OUT"
    FAILURES=$((FAILURES + 1))
fi

info "Deletando da tabela 'event_sequence' (~1.109 linhas)..."
if DELETE_OUT=$(opencode db "DELETE FROM event_sequence;" 2>&1); then
    ok "event_sequence deletada."
elif [[ "$DELETE_OUT" == *"locked"* ]]; then
    err "  DELETE falhou — database is locked (opencode rodando)."
    err "  Pare o opencode e re-execute."
    FAILURES=$((FAILURES + 1))
else
    err "  DELETE falhou inesperadamente: $DELETE_OUT"
    FAILURES=$((FAILURES + 1))
fi

# Verificar contagens = 0
EVENT_COUNT=$(opencode db "SELECT COUNT(*) FROM event;" 2>/dev/null | tail -n 1 | tr -d '[:space:]' || echo "?")
SEQ_COUNT=$(opencode db "SELECT COUNT(*) FROM event_sequence;" 2>/dev/null | tail -n 1 | tr -d '[:space:]' || echo "?")

if [ "$EVENT_COUNT" = "0" ] && [ "$SEQ_COUNT" = "0" ]; then
    ok "Tabelas event ($EVENT_COUNT) e event_sequence ($SEQ_COUNT) vazias."
else
    warn "Contagens inesperadas: event=$EVENT_COUNT, event_sequence=$SEQ_COUNT"
fi

# =============================================================================
# TASK 5: Deletar todas as sessões (cascade)
# =============================================================================

step "5 — Deletar todas as sessões"

SESSION_COUNT_BEFORE=$(opencode db "SELECT COUNT(*) FROM session;" 2>/dev/null | tail -n 1 | tr -d '[:space:]' || echo "?")
info "Sessões antes: $SESSION_COUNT_BEFORE"

info "Executando DELETE FROM session (cascade para message/part/todo)..."
if DELETE_OUT=$(opencode db "DELETE FROM session;" 2>&1); then
    ok "session deletada (cascade aplicado)."
elif [[ "$DELETE_OUT" == *"locked"* ]]; then
    err "  DELETE falhou — database is locked (opencode rodando)."
    err "  Pare o opencode e re-execute."
    FAILURES=$((FAILURES + 1))
else
    err "  DELETE falhou inesperadamente: $DELETE_OUT"
    FAILURES=$((FAILURES + 1))
fi

# Verificar: session|message|part|todo|session_context_epoch
COUNTS=$(opencode db "SELECT (SELECT COUNT(*) FROM session) || '|' || (SELECT COUNT(*) FROM message) || '|' || (SELECT COUNT(*) FROM part) || '|' || (SELECT COUNT(*) FROM todo) || '|' || (SELECT COUNT(*) FROM session_context_epoch);" 2>/dev/null | tail -n 1 | tr -d '[:space:]' || echo "?|?|?|?|?")

if [ "$COUNTS" = "0|0|0|0|0" ]; then
    ok "Todas as tabelas de sessão vazias: session|message|part|todo|session_context_epoch = $COUNTS"
else
    warn "Contagens: $COUNTS (esperado 0|0|0|0|0)"
fi

# =============================================================================
# TASK 6: VACUUM — compactar o arquivo de ~3.6 GB
# =============================================================================

step "6 — VACUUM (compactar DB)"

DB_SIZE_BEFORE=$(du -sh "$OC_DB" 2>/dev/null | cut -f1 || echo "?")
info "Tamanho do DB antes: $DB_SIZE_BEFORE"

info "Executando VACUUM (pode demorar alguns segundos)..."
if opencode db "VACUUM;" 2>&1; then
    DB_SIZE_AFTER=$(du -sh "$OC_DB" 2>/dev/null | cut -f1 || echo "?")
    ok "VACUUM concluído. DB antes: $DB_SIZE_BEFORE → depois: $DB_SIZE_AFTER"

    # Verificar freelist
    FREELIST=$(opencode db "PRAGMA freelist_count;" 2>/dev/null | tail -n 1 | tr -d '[:space:]' || echo "?")
    if [ "$FREELIST" = "0" ]; then
        ok "Freelist count = 0 (sem páginas livres)."
    else
        warn "Freelist count = $FREELIST (esperado 0)."
    fi
else
    err "═══════════════════════════════════════════════════════════════"
    err "  VACUUM FALHOU — provavelmente 'database is locked'"
    err ""
    err "  O opencode provavelmente está rodando e segurando o lock."
    err "  Pare o opencode (via terminal fora do web UI) e execute"
    err "  este script novamente, ou execute manualmente:"
    err "    opencode db \"VACUUM;\""
    err "═══════════════════════════════════════════════════════════════"
    FAILURES=$((FAILURES + 1))
    warn "Continuando com as próximas tarefas..."
fi

# =============================================================================
# TASK 7: Truncar log (~36 MB)
# =============================================================================

step "7 — Truncar log"

if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(du -sh "$LOG_FILE" 2>/dev/null | cut -f1 || echo "?")
    info "Log antes: $LOG_SIZE"
    truncate -s 0 "$LOG_FILE"
    ok "Log truncado (0 bytes)."
else
    info "Log não encontrado ($LOG_FILE) — nada a fazer."
fi

# =============================================================================
# TASK 8: Limpar tool-output (~1.7 MB)
# =============================================================================

step "8 — Limpar tool-output"

if [ -d "$TO_DIR" ]; then
    TO_SIZE=$(du -sh "$TO_DIR" 2>/dev/null | cut -f1 || echo "?")
    info "tool-output antes: $TO_SIZE"
    rm -f "$TO_DIR"/tool_* 2>/dev/null || true
    TO_AFTER=$(du -sh "$TO_DIR" 2>/dev/null | cut -f1 || echo "0")
    ok "tool-output limpo: $TO_AFTER"
else
    info "Diretório tool-output não encontrado — nada a fazer."
fi

# =============================================================================
# TASK 9: Limpar cache de providers (~8 MB)
# =============================================================================

step "9 — Limpar cache de providers"

# NUNCA tocar em bin/ nem packages/ — apenas models.json e tmp órfãos
info "Removendo models.json e tmp órfãos..."
rm -f "$OC_CACHE/models.json" 2>/dev/null || true
rm -f "$OC_CACHE/models.json."*.tmp 2>/dev/null || true
ok "Cache limpo (models.json será recriado na próxima execução)."

# Verificar que bin/ e packages/ estão intactos
if [ -d "$OC_CACHE/bin" ] && [ -d "$OC_CACHE/packages" ]; then
    ok "bin/ e packages/ preservados."
else
    warn "bin/ ou packages/ não encontrados (ok se primeira execução)."
fi

# =============================================================================
# TASK 10: Snapshots (OPCIONAL)
# =============================================================================

step "10 — Snapshots (opcional)"

if [ "$LIMPAR_SNAPSHOTS" = "1" ]; then
    if [ -d "$SNAP_DIR" ]; then
        SNAP_SIZE=$(du -sh "$SNAP_DIR" 2>/dev/null | cut -f1 || echo "?")
        info "Snapshots antes: $SNAP_SIZE"
        info "Removendo todos os snapshots..."
        rm -rf "${SNAP_DIR:?}/"* 2>/dev/null || true
        ok "Snapshots removidos. (Serão recriados quando projetos forem abertos.)"
    else
        info "Diretório de snapshots não encontrado — nada a fazer."
    fi
else
    info "Pulado (LIMPAR_SNAPSHOTS=0). Para limpar: LIMPAR_SNAPSHOTS=1 $0"
fi

# =============================================================================
# TASK 11: Verificação pós-limpeza
# =============================================================================

step "11 — Verificação pós-limpeza"

echo ""
info "━━━ Tamanhos depois da limpeza ━━━"
TAM_DATA_DEPOIS=$(du -sh "$OC_DATA" 2>/dev/null | cut -f1 || echo "?")
TAM_CACHE_DEPOIS=$(du -sh "$OC_CACHE" 2>/dev/null | cut -f1 || echo "?")
echo "  ~/.local/share/opencode/ = $TAM_DATA_DEPOIS  (antes: $TAM_DATA_ANTES)"
echo "  ~/.cache/opencode/       = $TAM_CACHE_DEPOIS  (antes: $TAM_CACHE_ANTES)"
echo ""

info "━━━ Contagens no DB ━━━"
SESSION_COUNT=$(opencode db "SELECT COUNT(*) FROM session;" 2>/dev/null | tail -n 1 | tr -d '[:space:]' || echo "?")
EVENT_COUNT=$(opencode db "SELECT COUNT(*) FROM event;" 2>/dev/null | tail -n 1 | tr -d '[:space:]' || echo "?")
echo "  sessions: $SESSION_COUNT  |  events: $EVENT_COUNT"
echo ""

info "━━━ opencode session list ━━━"
opencode session list 2>&1 || warn "session list falhou"
echo ""

info "━━━ opencode stats ━━━"
opencode stats 2>&1 || warn "stats falhou"
echo ""

info "━━━ opencode debug paths ━━━"
opencode debug paths 2>&1 || warn "debug paths falhou"
echo ""

info "━━━ Teste funcional ━━━"
TEST_LOG=$(mktemp)
TEST_STATUS=0
timeout 60 opencode run "teste pós-limpeza" --print-logs > "$TEST_LOG" 2>&1 || TEST_STATUS=$?
head -5 "$TEST_LOG"
rm -f "$TEST_LOG"
if [ "$TEST_STATUS" -eq 0 ]; then
    ok "Teste funcional passou — opencode operacional."
else
    warn "Teste funcional falhou (exit $TEST_STATUS) — opencode pode estar com problemas."
fi
echo ""

# =============================================================================
# RESUMO FINAL
# =============================================================================

if [ "$FAILURES" -gt 0 ]; then
    warn "Limpeza incompleta — $FAILURES erros."
fi

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  LIMPEZA CONCLUÍDA${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Antes:"
echo "    ~/.local/share/opencode/ = $TAM_DATA_ANTES"
echo "    ~/.cache/opencode/       = $TAM_CACHE_ANTES"
echo ""
echo "  Depois:"
echo "    ~/.local/share/opencode/ = $TAM_DATA_DEPOIS"
echo "    ~/.cache/opencode/       = $TAM_CACHE_DEPOIS"
echo ""
echo "  Backup preservado em: $BACKUP_FILE"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# =============================================================================
# INSTRUÇÕES DE RESTAURAÇÃO
# =============================================================================

echo -e "${CYAN}Para restaurar (se mudar de ideia):${NC}"
echo ""
echo "  1. Pare o opencode:"
echo "     opencode_web_stop"
echo ""
echo "  2. Restaure o backup:"
echo "     cp $BACKUP_FILE $OC_DB"
echo "     rm -f ${OC_DB}-wal ${OC_DB}-shm"
echo ""
echo "  3. Reinicie o opencode:"
echo "     opencode_web"
echo ""
echo -e "${CYAN}Backup: $BACKUP_FILE (${BACKUP_SIZE_GB} GB)${NC}"
echo ""

exit 0