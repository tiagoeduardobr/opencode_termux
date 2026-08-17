# ADR-009: Limpeza de órfãos/zumbis no stop script

## Status

Accepted

## Date

2026-08-14

## Context

O `bin/opencode-web-stop.sh` original matava apenas o PID do proot via PID_FILE.
Processos órfãos (`run-cloudflare-tunnel.sh`, `opencode web`, `cloudflared`)
sobreviviam à morte do proot. Processos zumbis `<defunct>` não morriam com `kill`
comum. Cenário real observado: órfãos reparentados ao init + zumbi `<defunct>` do proot.

## Decision

Reescrever `bin/opencode-web-stop.sh` (commit `dc4f00a`):
- Carregar `.env` via `$SCRIPT_DIR` com defaults (`OPENCODE_PORT`/`OPENCODE_HOSTNAME`)
- Helpers `is_zombie()` (case `Z*` via `ps -o stat=`) e `kill_graceful()` (SIGTERM → 3×1s → SIGKILL, zombie-aware)
- Limpeza de órfãos **por padrão** (sempre, mesmo sem PID_FILE) em duas fases:
  - Fase A: SIGTERM em todos os processos alvo
  - Espera 3×1s (zombie-aware, dedup com `sort -n | uniq`)
  - Fase B: SIGKILL nos sobreviventes
- Alvos: `run-cloudflare-tunnel.sh` (variável `SCRIPT_PATTERN`), processo na porta `$OPENCODE_PORT` (via `port_pids()`: lsof → fuser fallback), `cloudflared tunnel --url http://127.0.0.1:${PORT}` (padrão com porta)
- **NUNCA** `pkill -f "opencode web"` (risco de matar sessão TUI em outro terminal)
- Verificação final: zumbis → INFO (reap pelo init), vivos → WARN com `ps`
- Cleanup inalterado: PID file, notify file, log, `stty sane`, `termux-wake-unlock`

## Alternatives Considered

1. **Manter kill por PID apenas** — Rejeitado: não resolve o cenário real de órfãos reparentados
2. **`pkill -f "opencode web"` genérico** — Rejeitado: risco de matar sessão TUI em outro terminal
3. **Trap de cleanup só no `run-cloudflare-tunnel.sh`** — Mantido como caminho principal, mas insuficiente sozinho (órfãos já observados sobrevivem ao trap quando proot é morto com SIGKILL)
4. **Depender de `--kill-on-exit` do proot** — Rejeitado: não garante morte dos filhos (evidência real de que falha)

## Consequences

### Positivos
- Stop script limpa cenários reais observados no device
- Zumbis não bloqueiam o script (tratamento zombie-aware)
- Padrões de kill seguros (nunca `pkill -f "opencode web"`)
- Verificação final fornece visibilidade sobre processos remanescentes

### Negativos
- Limpeza por porta pode matar processo não relacionado na mesma porta — Mitigado: a porta é configurável e do projeto; o caminho principal via trap continua sendo o `run-cloudflare-tunnel.sh`
- `lsof`/`fuser` podem ser cegos para processos em outro namespace — Mitigado: WARN único (`TOOLS_WARNED`) e caminho principal via trap

## Related

- [MULTI_AGENT_ORCHESTRATION.md](../MULTI_AGENT_ORCHESTRATION.md)
- [SESSION_CONTEXT_20260618.md](../SESSION_CONTEXT_20260618.md)
- [Plano de implementação](../../.opencode/plans/20260814_1142_stop-script-zombies.md)
