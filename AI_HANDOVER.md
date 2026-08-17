# AI_HANDOVER — 2026-08-17

> Snapshot auto-contido da sessão. Criado antes da exclusão da DB do OpenCode
> (`~/.local/share/opencode/opencode.db`, ~856MB + WAL 279MB) para preservar
> contexto para agentes futuros que não terão acesso ao histórico.

## Propósito

Preservar contexto de sessão para agentes futuros. O OpenCode DB cresceu demais
(~856MB + WAL 279MB) e causa o erro "Question request not found". O usuário pretende
excluir a DB — este documento garante que o contexto da sessão não se perca.

## Estado do Repositório

- Branch: `main` em commit `3497e95`
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

## Sessão de 2026-08-17 — Upgrades Sequenciais do OpenCode (1.18.2 → 1.18.18)

### Resumo
Cadeia de upgrades do OpenCode (CLI + plugin) de 1.18.3 até 1.18.18, realizados
ao longo de múltiplas sessões. Cada upgrade seguiu o mesmo pipeline:
branch → npm install → plugin bump + docs → commit → merge direto (fast-forward).

### Commits de Upgrade (em ordem cronológica)
| Commit | Versão | Data | Destaque |
|--------|--------|------|----------|
| `84e3547` | 1.18.3 | ~Jul 16 | Desktop bugfixes, subagent picker |
| `ec40e00` | 1.18.4 | ~Jul 20 | Desktop v2 layout, subagentes aninhados, GPT-5.6 Azure |
| `072dcea` | 1.18.5 | ~Jul 24 | Fix Claude adaptive thinking, Mistral reasoning |
| `65b296a` | 1.18.10 | ~Jul 28 | MCP OAuth/reconnect, legacy MCP compat |
| `57db19e` | 1.18.11 | ~Aug 1 | Fix MCP SSE reconnect loops, provider reasoning |
| `f391510` | 1.18.13 | ~Aug 4 | TUI PR context, desktop RTL/i18n |
| `d9f52d4` | 1.18.15 | ~Aug 7 | xAI device-code flow, retry caps |
| `834e3ca` | 1.18.18 | Aug 13 | Config parsing robusto, retry caps, fix Kimi/xAI |

### Versões Puladas (com justificativa)
- **1.18.6–1.18.9**: patches de core/desktop, sem impacto no workflow → saltou para 1.18.10
- **1.18.12**: Azure GPT-5.5+ reasoning fix → saltou para 1.18.13 (junto com desktop i18n)
- **1.18.14**: xAI device-code flow → saltou para 1.18.15 (retry caps)

### Arquivos Modificados por Upgrade
Cada upgrade tocou os mesmos 6 arquivos:
1. `opencode` CLI global (`npm install -g opencode-linux-arm64@X.Y.Z --force`)
2. `.config/opencode/package.json` (plugin `^old` → `^new`)
3. `.config/opencode/package-lock.json` (via `npm install`)
4. `AGENTS.md` (nova linha em "Melhorias Recentes")
5. `docs/MULTI_AGENT_ORCHESTRATION.md` (linha 4 — versão do sistema)
6. `docs/SESSION_CONTEXT_20260618.md` (nova seção por upgrade)

### Decisões de Workflow
- **Merge direto sempre**: usuário nunca quer PRs — merges são fast-forward
- **Pattern de upgrade**: branch `feature/upgrade-opencode-X-Y-Z` → npm install → dev edita → git-commit commit + merge + delete branch
- **Permission.task**: não funciona em frontmatter .md (parser ignora); usar `opencode.json` (documentado em 9.6.3 de MULTI_AGENT_ORCHESTRATION.md)
- **subagent_depth=0**: subagentes isolados por padrão no OpenCode 1.18.2+

## Sessão de 2026-08-17 — Ajustes de Coerência Documental e Agentes

### Resumo
Correção de inconsistências documentais e ajustes nos agentes do sistema multi-agente.

### Mudanças Implementadas

| Commit | Descrição |
|--------|-----------|
| `19676cf` | 23 inconsistências corrigidas em 5 arquivos (AGENTS.md, MULTI_AGENT_ORCHESTRATION.md, SESSION_CONTEXT, README.md, ADR-005) |
| `ba0df7f` | MULTI_AGENT_ORCHESTRATION.md: skill count 49→50, nova seção 4.5 "Como Adicionar Skills a um Projeto" |
| `a83ec74` | task-planner.md: detecção obrigatória de skills por tecnologia (17 stacks mapeadas) |
| `3497e95` | dev.md: regra explícita "NUNCA sugerir commit" — task-build controla momento |

### Detalhes por Mudança

#### Coerência Documental (19676cf)
- ADR-005: plan-reviewer invocado via code-review, timeouts corrigidos
- MULTI_AGENT_ORCHESTRATION.md seção 2.1: plan-reviewer, code review, revisão consolidada
- AGENTS.md: steps 0-8, melhorias atualizadas, referências quebradas corrigidas
- SESSION_CONTEXT: data 10/07/2026, 7 mudanças documentadas
- README.md: 50 skills, plan-reviewer, code review, aritmética corrigida

#### task-planner.md — Skills por Tecnologia (a83ec74)
17 stacks mapeados com skills obrigatórios:
| Tecnologia | Skills Obrigatórios |
|------------|---------------------|
| React Native | `react-native-best-practices` |
| Expo | `expo-*` (conforme módulo) |
| Python | `python-pro` |
| FastAPI | `fastapi-expert` |
| PostgreSQL | `postgres-pro`, `sql-pro` |
| Terraform | `terraform-engineer` |
| Kubernetes | `devops-engineer` |
| AWS/Azure/GCP | `cloud-architect` |
| Frontend Web | `frontend-complete`, `code-architecture-tailwind-v4-best-practices` |
| React | `javascript-typescript` |
| Data Science | `data-science-expert` |
| Monitoring | `monitoring-expert` |
| Security | `security-reviewer`, `secure-code-guardian`, `api-security-best-practices` |
| Architecture | `architecture-designer`, `microservices-architect` |
| SRE | `sre-engineer` |
| Git | `using-git-worktrees` |

Regra: skills de tecnologia são OBRIGATÓRIOS mesmo que task-build indique outros.

#### dev.md — Não Sugerir Commit (3497e95)
Adicionada seção `### Commit` nas Regras do dev.md:
```markdown
### Commit
- NUNCA sugerir ou iniciar commit — task-build decide o momento correto
- NUNCA mencionar "pronto para commit" ou "commitar agora"
- Retornar apenas "Pronto para review" ou "Precisa de ajustes"
```

### Pendências Conhecidas
1. `bin/opencode-tailscale-stop.sh` tem o mesmo problema de órfãos (fora de escopo)
2. Tailscale ainda não instalado no device (instruções em `docs/tailscale/README.md`)
3. `docs/tailscale/README.md` ainda usa `pkg install tailscale` (INCORRETO — precisa compilar do fonte)

## Sessão de 2026-08-17 — SSH/SFTP Access para Termux

### Resumo
Implementação de scripts para acesso SSH/SFTP ao Termux via Termius, com notificação push ntfy.sh incluindo botão de copiar.

### Contexto
Usuário queria acessar arquivos do Termux remotamente via SFTP. Pesquisou sobre opções (JuiceSSH, Termius) e escolheu Termius. Pedeu para criar script que:
- Inicia sshd se não estiver rodando
- Detecta IP do dispositivo
- Envia notificação ntfy push com comando SSH formatado (botão copiar via `copy` action do ntfy)
- Envia notificação local Termux com botão copiar

### Descoberta Importante
ntfy.sh suporta **action type `copy`** via header `Actions: copy, <label>, <value>` — copia valor para o clipboard do Android. Isso permite que o usuário copie o comando SSH com um toque na notificação.

### Arquivos Criados

| Arquivo | Descrição |
|---|---|
| `bin/termux-ssh.sh` | Script principal: inicia sshd, detecta IP, envia notificações (ntfy + Termux local) |
| `bin/termux-ssh-stop.sh` | Script de parada: graceful kill → force kill → cleanup |
| `docs/termux/ssh-sftp-access.md` | Documentação de referência SSH/SFTP |

### Arquivos Modificados

| Arquivo | Mudança |
|---|---|
| `shell/aliases.sh` | Adicionados aliases `termux_ssh` e `termux_ssh_stop` |
| `.env` | Adicionada variável `SSH_PORT=8022` |
| `.env.example` | Adicionada variável `SSH_PORT=8022` |
| `AGENTS.md` | Seção SSH em scripts, docs e comandos úteis |
| `README.md` | Estrutura, seção SSH/SFTP, referência dos scripts, 3 perguntas FAQ |

### Commit
- `b5b6e7f` — `feat: add SSH/SFTP access scripts for remote Termux file management`
- Pushed para `main → origin/main`

### Padrões do Projeto Confirmados
- Shebang Termux: `#!/data/data/com.termux/files/usr/bin/bash`
- `[INFO]`/`[ERROR]`/`[OK]` messages (sem cores)
- `.env` loading via `$SCRIPT_DIR` com `set -a; source ...; set +a`
- PID file pattern com `kill -0`
- `termux-notification` com `--id`, `--ongoing`, `--button1`/`--button2`
- Stop script: graceful kill → 3×1s wait → force kill → cleanup
- ntfy push: `curl -s -d "..." "https://ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 || true`

### Uso
```bash
termux_ssh          # inicia sshd + notifica IP
termux_ssh_stop     # para sshd
```
Porta padrão: 8022. Autenticação via senha (`passwd`).

---

*Documento gerado em 2026-08-17. Atualizar após mudanças significativas no repositório.*