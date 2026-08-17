# AI_HANDOVER — 2026-08-17

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

## Sessão de 2026-07-11 — Integração Tailscale

### Problema
O Cloudflare Quick Tunnel bloqueia SSE (Server-Sent Events), que o OpenCode Web usa
em `/global/event` para notificações em tempo real. O frontend precisava de refresh
manual. Tailscale foi escolhido como alternativa — VPN mesh que preserva SSE/WebSocket.

### Implementação (commits 7c048b3 + 49ee73c)
7 arquivos criados/modificados via workflow completo (task-build → code-review → commit):

| Arquivo | Tipo | Descrição |
|---|---|---|
| `run-opencode-tailscale.sh` | Novo | Script proot que inicia opencode web e sinaliza prontidão |
| `bin/opencode-tailscale.sh` | Novo | Wrapper Termux: wake lock, proot, tailscale serve, notificações |
| `bin/opencode-tailscale-stop.sh` | Novo | Stop script: graceful kill, stty sane, wake-unlock |
| `docs/tailscale/README.md` | Novo | Documentação completa (235 linhas) |
| `shell/aliases.sh` | Modificado | Adicionados aliases `opencode_tailscale` / `opencode_tailscale_stop` |
| `scripts/setup.sh` | Modificado | Seção 4 opcional para Tailscale |
| `.env.example` | Modificado | Variável `TAILSCALE_SERVE_HTTP=true` |
| `AGENTS.md` | Modificado | Estrutura, scripts, comandos e referências Tailscale |

### Descoberta Crítica: Tailscale NÃO funciona dentro do proot
O daemon `tailscaled` precisa de permissões de netlink que o proot não fornece:
```
netmon.New: route ip+net: netlinkrib: permission denied
```
Mesmo com `--tun=userspace-networking`, o erro persiste. **Tailscale só funciona no host (Termux).**

### Solução: Compilar Tailscale do fonte no Termux
Os binários pré-compilados de `pkgs.tailscale.com` não funcionam no Termux (Bionic libc).
A solução é compilar do fonte:

```bash
# Fora do proot, no Termux
pkg install golang -y
cd "$HOME"
git clone https://github.com/tailscale/tailscale --depth=1
cd tailscale
go install tailscale.com/cmd/tailscale{,d}
```

Aliases para `~/.bashrc`:
```bash
export PATH="$HOME/go/bin:$PATH"
alias tailscaled='tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 --socket $PREFIX/var/run/tailscaled.sock --statedir $HOME/.config/tailscale/'
alias tailscale='tailscale --socket $PREFIX/var/run/tailscaled.sock'
```

Iniciar:
```bash
mkdir -p $HOME/.config/tailscale $PREFIX/var/run
tailscaled &
tailscale up
```

> **Fonte**: github.com/termux/termux-packages/issues/10166
> **Nota**: Em alguns dispositivos pode continuar dando `netlinkrib` mesmo compilado do fonte.

### Estado Atual
- Código commitado em `main` (commits `7c048b3` + `49ee73c`)
- Scripts criados e funcionais (documentados em `docs/tailscale/README.md`)
- Tailscale **ainda não instalado no device** — instruções de instalação corretas acima
- Documentação em `docs/tailscale/README.md` ainda usa `pkg install tailscale` (INCORRETO — precisa ser atualizado com as instruções corretas de compilação)
- `bin/opencode-tailscale-stop.sh` usa `tailscale serve --remove` (corrigido na segunda revisão)

### Pendências
1. **Atualizar `docs/tailscale/README.md`** — substituir `pkg install tailscale` pelas instruções corretas de compilação
2. **Testar Tailscale no device** — compilar do fonte e verificar se funciona
3. **Testar `tailscale serve`** — verificar se consegue expor porta 4096 na rede Tailscale
4. **Se `netlinkrib` persistir** — considerar alternativa: localhost.run (SSH tunnel gratuito)

---

*Documento gerado em 2026-08-17. Atualizar após mudanças significativas no repositório.*