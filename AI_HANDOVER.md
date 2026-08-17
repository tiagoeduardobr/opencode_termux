# AI_HANDOVER — 2026-08-14

> Snapshot auto-contido da sessão. Criado antes da exclusão da DB do OpenCode
> (`~/.local/share/opencode/opencode.db`, ~856MB + WAL 279MB) para preservar
> contexto para agentes futuros que não terão acesso ao histórico.

## Propósito

Preservar contexto de sessão para agentes futuros. O OpenCode DB cresceu demais
(~856MB + WAL 279MB) e causa o erro "Question request not found". O usuário pretende
excluir a DB — este documento garante que o contexto da sessão não se perca.

## Estado do Repositório

- Branch: `main` em commit `dc4f00a`
- Sincronizado com `origin/main`
- Working tree limpo (sem alterações pendentes)
- OpenCode versão: 1.18.18
- Device: Poco X7 Pro, Android 14, MIUI HyperOS, Termux

## Sessão de 2026-08-14 — Melhoria do Stop Script

### Problema
O `bin/opencode-web-stop.sh` original matava apenas o PID do proot via PID_FILE.
Processos órfãos (`run-cloudflare-tunnel.sh`, `opencode web`, `cloudflared`) sobreviviam
à morte do proot. Processos zumbis `<defunct>` não morriam com `kill` comum.

### Solução (commit dc4f00a)
Reescrita do stop script (32→140 linhas) com:
1. Carregamento de `.env` via `$SCRIPT_DIR` com defaults
2. Helpers `is_zombie()` e `kill_graceful()` (SIGTERM → 3×1s → SIGKILL, zombie-aware)
3. Limpeza de órfãos que roda **sempre** (mesmo sem PID_FILE):
   - Fase A: SIGTERM em todos os processos alvo
   - Espera 3×1s (zombie-aware, dedup com `sort -n | uniq`)
   - Fase B: SIGKILL nos sobreviventes
   - Alvos: `run-cloudflare-tunnel.sh`, processo na porta, `cloudflared tunnel` com porta
4. **NUNCA** `pkill -f "opencode web"` (risco de matar sessão TUI em outro terminal)
5. Verificação final: zumbis → INFO (reap pelo init), vivos → WARN com `ps`
6. Cleanup: PID file, notify file, log, `stty sane`, `termux-wake-unlock`

### Validação no Device (4 cenários)
1. Stop normal (service rodando)
2. Reprodução do bug real (`kill -9` do proot, verificando limpeza de órfãos)
3. Dry run (sem serviço ativo)
4. Porta customizada (OPENCODE_PORT diferente)

## Arquitetura dos Scripts

| Script | Local | Função |
|--------|-------|--------|
| `bin/opencode-web.sh` | Host Termux | Manager fire-and-forget: inicia proot com opencode web + cloudflared tunnel |
| `run-cloudflare-tunnel.sh` | Dentro do proot | Executa `opencode web` + `cloudflared tunnel` + ntfy push |
| `bin/opencode-web-stop.sh` | Host Termux | **Novo**: mata proot + limpa órfãos/zumbis por padrão |
| `bin/opencode-tailscale.sh` | Host Termux | Alternativa ao Cloudflare (usa Tailscale) |
| `bin/opencode-tailscale-stop.sh` | Host Termux | Para Tailscale (pode ter o mesmo problema de órfãos) |
| `bin/termux-ssh.sh` | Host Termux | Inicia sshd para acesso remoto |
| `bin/termux-ssh-stop.sh` | Host Termux | Para sshd |

## Convenções Importantes do Projeto

- **Shebang Termux**: `#!/data/data/com.termux/files/usr/bin/bash` (não `/bin/bash`)
- **Shebang proot**: `#!/usr/bin/env bash`
- **`--shared-tmp`**: mapeia `/tmp` do proot para `$PREFIX/tmp` do Termux (essencial para handoff de URL)
- **Fire-and-forget**: `disown` + PID file — opencode tem bug onde Ctrl+C não termina (#21505)
- **`kill -0` + `is_zombie()`**: `kill -0` retorna 0 para zumbis — não é teste suficiente de vida; stop script combina com `is_zombie()`
- **`stty sane`**: reset de terminal pós-proot (quirk Termux)
- **`0.0.0.0` crasha no proot**: `opencode web --hostname 0.0.0.0` falha com `getifaddrs`; usar `127.0.0.1`
- **`.env` loading**: scripts carregam de `$SCRIPT_DIR` (raiz do repo), não do CWD
- **`termux-notification-remove` removido**: causava abertura de config de bateria em MIUI/Xiaomi
- **`pkill -f "opencode web"` NUNCA**: risco de matar sessão TUI em outro terminal
- **`permission.task`**: funciona via `opencode.json`, NÃO no frontmatter .md dos agentes

## Decisões Documentadas

- Ver `docs/decisions/` (ADR-001 a ADR-008, mais ADR-009 se já criado)
- Ver `docs/MULTI_AGENT_ORCHESTRATION.md` para orquestração completa

## Pendências / Conhecimento Útil

- **DB do OpenCode**: para excluir, `rm ~/.local/share/opencode/opencode.db ~/.local/share/opencode/opencode.db-wal ~/.local/share/opencode/opencode.db-shm`
- **Recriar contexto do stop script**: plano detalhado em `.opencode/plans/20260814_1142_stop-script-zombies.md`
- **Follow-up conhecido**: `bin/opencode-tailscale-stop.sh` tem o mesmo problema de órfãos (fora de escopo desta sessão)
- **Testes integrados**: todos validados no device (4 cenários descritos acima)

---

*Documento gerado em 2026-08-14. Atualizar após mudanças significativas no repositório.*