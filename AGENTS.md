# opencode_termux — Guia para Agentes de IA

Repositório auto-contido que centraliza scripts Termux + config OpenCode global (skills, agents) + setup.sh.

## Estrutura

```
opencode_termux/
├── .config/opencode/           ← GLOBAL (symlink de ~/.config/opencode/)
│   ├── opencode.jsonc          ← config global do opencode
│   ├── package.json            ← dependências de skills (npm)
│   ├── skills/                 ← 50 skills (27 globais + 14 do obra/superpowers + 10 novas upstream)
│   │   ├── code-reviewer/
│   │   ├── executing-plans/
│   │   ├── design-system/            ← unificado de design-system-patterns + design-tokens
│   │   ├── frontend-complete/        ← unificado de frontend-design + designing-frontend-interfaces
│   │   └── ... (35 outras)
│   └── agents/                 ← subagentes (git-commit, code-review, task-planner, dev, task-build)
│       ├── git-commit.md
│       ├── code-review.md
│       ├── task-planner.md
│       ├── dev.md
│       └── task-build.md
├── opencode.json               ← config DO PROJETO (skills path, permissions)
├── run-cloudflare-tunnel.sh    ← script executado dentro do proot (Cloudflare)
├── run-opencode-tailscale.sh   ← script executado dentro do proot (Tailscale)
├── bin/
│   ├── opencode-web.sh            ← wrapper Termux (Cloudflare)
│   ├── opencode-web-stop.sh       ← stop script (Cloudflare)
│   ├── opencode-tailscale.sh      ← wrapper Termux (Tailscale)
│   ├── opencode-tailscale-stop.sh ← stop script (Tailscale)
│   ├── termux-ssh.sh              ← inicia sshd + notifica IP
│   └── termux-ssh-stop.sh         ← para sshd
├── shell/
│   └── aliases.sh              ← aliases bash (opencode_web, opencode_web_stop, opencode_tailscale, opencode_tailscale_stop)
├── scripts/
│   └── setup.sh                ← setup em device novo (backup, symlink, npm install)
├── docs/                       ← documentação de referência
│   ├── SESSION_CONTEXT_20260618.md ← contexto da sessão de criação
│   ├── proot-distro/
│   │   └── README.md           ← docs completas do proot-distro
│   ├── termux/
│   │   ├── filesystem-layout.md ← paths, $PREFIX, $TMPDIR
│   │   ├── termux-notification.md ← API de notificações
│   │   └── ssh-sftp-access.md   ← referência SSH/SFTP
│   └── cloudflare/
│       ├── quick-tunnel.md     ← Quick Tunnel / TryCloudflare
│       ├── downloads.md        ← cloudflared arm64 .deb
│       ├── config-file.md      ← YAML config structure
│       └── run-parameters.md   ← tunnel run flags
├── .env                        ← config real (OPENCODE_PORT, NTFY_TOPIC, PROJECT_DIR)
├── .env.example                ← template
├── README.md                   ← tutorial completo
└── AGENTS.md                   ← este arquivo
```

## Arquitetura de Config

- **`~/.config/opencode/`** é um **symlink** apontando para `opencode_termux/.config/opencode/`
- Todos os projetos enxergam skills e agentes automaticamente via `~/.config/opencode/`
- `opencode_termux/opencode.json` usa paths relativos (`.config/opencode/...`)
- `parecer_descritivo/opencode.json` NÃO precisa ser alterado — skills/agents chegam via symlink global
- Plans específicos de projeto (ex: `parecer_descritivo/.opencode/plans/`) permanecem no projeto

## Setup em Device Novo

Para instruções detalhadas de setup, veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 4.2).

Resumo rápido:
```bash
git clone <url> opencode_termux
cd opencode_termux
bash scripts/setup.sh
source shell/aliases.sh        # ou adicionar ao ~/.bashrc
cp .env.example .env           # e editar
```

## Scripts de Execução

### `bin/opencode-web.sh`

Manager fire-and-forget para expor OpenCode Web via Cloudflare Quick Tunnel.

Variáveis (via `.env` ou env var):
| Variável | Default | Descrição |
|---|---|---|
| `OPENCODE_PORT` | `4096` | Porta local do OpenCode Web |
| `OPENCODE_HOSTNAME` | `127.0.0.1` | Hostname do opencode web (usar `127.0.0.1` dentro do proot — `0.0.0.0` crasha com `getifaddrs`)|
| `NTFY_TOPIC` | `opencode-tunnel` | Tópico ntfy.sh para notificação |
| `PROJECT_DIR` | diretório do script | Onde está `run-cloudflare-tunnel.sh` (raiz deste repo, não o projeto de destino) |
| `NOTIFY_FILE` | `$PREFIX/tmp/opencode_url.txt` | Handoff da URL |
| `PID_FILE` | `$PREFIX/tmp/opencode_web.pid` | PID do processo |
| `LOG_FILE` | `$PREFIX/tmp/opencode_web.log` | Log da execução no proot |

### `run-cloudflare-tunnel.sh`

Executado **dentro do proot** (`--shared-tmp`). Sobe `opencode web` + `cloudflared tunnel` + ntfy push.

### `bin/opencode-tailscale.sh`

Wrapper fire-and-forget para expor OpenCode Web via Tailscale (alternativa ao Cloudflare Quick Tunnel).

Variáveis (via `.env` ou env var):
| Variável | Default | Descrição |
|---|---|---|
| `OPENCODE_PORT` | `4096` | Porta local do OpenCode Web |
| `OPENCODE_HOSTNAME` | `127.0.0.1` | Hostname do opencode web |
| `NTFY_TOPIC` | `opencode-tunnel` | Tópico ntfy.sh para notificação |
| `NOTIFY_FILE` | `$PREFIX/tmp/opencode_tailscale_url.txt` | Handoff da URL |
| `PID_FILE` | `$PREFIX/tmp/opencode_tailscale.pid` | PID do processo |
| `LOG_FILE` | `$PREFIX/tmp/opencode_tailscale.log` | Log da execução no proot |
| `TAILSCALE_SERVE_HTTP` | `true` | Usar `tailscale serve --http` (HTTP) ou sem (HTTPS) |

### `bin/termux-ssh.sh`

Gerencia o serviço SSH do Termux para acesso remoto via SFTP/SSH.

Variáveis (via `.env` ou env var):
| Variável | Default | Descrição |
|---|---|---|
| `NTFY_TOPIC` | `opencode-tunnel` | Tópico ntfy.sh para notificação |
| `SSH_PORT` | `8022` | Porta do sshd |
| `SSHD_PID_FILE` | `$PREFIX/tmp/termux_sshd.pid` | Arquivo do PID |

### `bin/termux-ssh-stop.sh`

Para o serviço sshd: kill graceful → kill -9 → cleanup.

## Skills e Subagentes

50 skills em `.config/opencode/skills/` (27 globais + 14 do obra/superpowers + 10 novas upstream), além de `customize-opencode` (built-in do opencode, sem diretório).
Subagentes: `git-commit`, `code-review`, `task-planner`, `dev`, `task-build` (prompts em `.config/opencode/agents/`).
Lista completa: `opencode.json` permission.skill e `docs/SESSION_CONTEXT_20260618.md`.

## Dependências (device)

- `npm install -g opencode-linux-arm64 --force` (dentro do proot Ubuntu)
- `cloudflared` (dentro do proot, .deb arm64)

## Convenções e Gotchas

- **Shebang**: Scripts Termux usam `#!/data/data/com.termux/files/usr/bin/bash`
  (não `/bin/bash` — não existe no Termux). Scripts dentro do proot usam
  `#!/usr/bin/env bash`.
- **`--shared-tmp`**: Mapeia `/tmp` do proot para `$PREFIX/tmp` do Termux.
  Essencial para handoff da URL via `$PREFIX/tmp/opencode_url.txt`. Não remover.
  → Detalhes: `docs/proot-distro/README.md`, `docs/termux/filesystem-layout.md`
- **`exec` no proot**: Dentro do proot, o `bash -c` faz `cd "$1" && exec ./run-cloudflare-tunnel.sh`
  — substitui o bash, evita processo orfão. Não refatorar para `bash -c` sem `exec`.
- **Fire-and-forget**: `disown` + PID file — o opencode tem bug onde Ctrl+C não
  termina (#21505). O manager só inicia e sai; use `opencode_web_stop` para parar.
- **`kill -0`**: Padrão POSIX para testar se processo existe, mas retorna 0 para
  processos zumbis (não é teste suficiente de vida). O stop script combina
  `kill -0` com `is_zombie()` para detectar zumbis antes de tentar matar.
  A limpeza de órfãos agora roda por padrão (mesmo sem PID file).
- **`stty sane`** no stop: Reset de terminal pós-proot (quirk Termux). Não remover.
- **`termux-notification-remove`** removido: Causa abertura de configurações de bateria
  em MIUI/Xiaomi. A notificação com `--id` e `--ongoing` é limpa automaticamente
  pelo Android quando o processo termina.
  → Detalhes: `docs/termux/termux-notification.md`
- **`.env` loading**: Scripts carregam `.env` de `$SCRIPT_DIR` (raiz do repo), não do CWD.
  `run-cloudflare-tunnel.sh` dentro do proot também carrega do CWD (que é o mesmo dir).
- **`.config/opencode/.gitignore`**: Ignora `node_modules`, `bun.lock` e `.gitignore`
  — intencional (mantém package.json/lock versionados, exclui node_modules).
- **`opencode.json`**: usa paths relativos `.config/opencode/skills/`.
  Agentes são definidos via markdown em `.config/opencode/agents/` (auto-descobertos).
- **`permission.task` (OpenCode 1.18.2)**: Substitui o `rbac` custom. Controla
  quais subagentes um agente pode invocar via Task tool.

  > **⚠️ WARN**: `permission.task` NÃO é suportado no frontmatter .md dos agentes.
  > O parser do OpenCode 1.18.2 ignora este campo em arquivos .md.
  > Para configurar isolamento de subagentes, use `opencode.json` do projeto (seção `"agent"`).
  > Ver seção 9.6.3 de `docs/MULTI_AGENT_ORCHESTRATION.md` para detalhes.

  No `opencode.json`, o formato é:
  ```json
  "permission": {
    "task": []
  }
  ```

  Agentes primários (ex: `task-build`) não precisam de `permission.task` —
  podem chamar todos os subagentes por padrão.
  
  → Detalhes: `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 5.3)
  
- **Cores dos agentes**: Cada agente tem uma cor distinta no TUI:
  `task-build`=blue, `task-planner`=green, `dev`=orange, `code-review`=purple, `git-commit`=gray.
- **`0.0.0.0` crasha dentro do proot**: O `opencode web --hostname 0.0.0.0` falha
  com `getifaddrs returned an error` porque o proot não expõe interfaces de rede.
  Use `127.0.0.1` (default) dentro do proot; o cloudflared conecta em `127.0.0.1`.
  → Detalhes: `docs/proot-distro/README.md` (section: networking limitations)
- **Log de diagnóstico**: Saída do proot vai para `$PREFIX/tmp/opencode_web.log`.
  Se o tunnel não subir, consulte este arquivo.

## Referências Externas

Documentação de referência para as ferramentas utilizadas, salva localmente
para acesso offline e versionamento no repositório.

| Doc | Cobre | Usado por |
|---|---|---|
| `docs/proot-distro/README.md` | Login, `--shared-tmp`, distros, troubleshooting | `opencode-web.sh`, `setup.sh` |
| `docs/termux/filesystem-layout.md` | `$PREFIX`, `$TMPDIR`, hierarquia de dirs | Todos os scripts (paths de handoff) |
| `docs/termux/termux-notification.md` | Flags, `--id`, `--ongoing`, `--action` | `opencode-web.sh` (notificação) |
| `docs/termux/ssh-sftp-access.md` | SSH/SFTP setup, Termius, caminhos | `termux-ssh.sh` |
| `docs/cloudflare/quick-tunnel.md` | URL format, stderr parsing, ephemeral tunnels | `run-cloudflare-tunnel.sh` |
| `docs/cloudflare/downloads.md` | `.deb` arm64, versões, checksums | `setup.sh`, README tutorial |
| `docs/cloudflare/config-file.md` | YAML structure, `ingress:` rules | Não usado ainda (futuro) |
| `docs/cloudflare/run-parameters.md` | `tunnel --url`, `--protocol`, log flags | `run-cloudflare-tunnel.sh` |
| `docs/tailscale/README.md` | Tailscale setup, uso, troubleshooting | `opencode-tailscale.sh` (alternativa ao Cloudflare) |

> **Staleness**: Estas docs são cópias estáticas de repositórios externos.
> Data de snapshot: **19/06/2026**. Se alguma ferramenta quebrar após atualização,
> verifique se a doc local ainda corresponde à versão instalada.

## Leitura Recomendada por Tarefa

| Tarefa | Docs para ler |
|---|---|
| **Setup em device novo** | `proot-distro/README.md`, `cloudflare/downloads.md`, `termux/filesystem-layout.md` |
| **Debug do tunnel não subir** | `cloudflare/quick-tunnel.md`, `cloudflare/run-parameters.md` |
| **Mudar porta/host do opencode** | `termux/filesystem-layout.md`, `cloudflare/config-file.md` |
| **Adicionar notificação customizada** | `termux/termux-notification.md` |
| **Atualizar cloudflared** | `cloudflare/downloads.md`, `cloudflare/run-parameters.md` |
| **Migrar de Quick Tunnel para named tunnel** | `cloudflare/config-file.md`, `cloudflare/run-parameters.md` |
| **Setup Tailscale** | `tailscale/README.md` |
| **Debug Tailscale** | `tailscale/README.md` (troubleshooting) |

## Agent Workflow — Orquestração

> **Visão geral**: Esta seção é um overview rápido dos workflows.
> Para documentação completa (templates, RBAC, circuit breaker, crash recovery,
> anti-padrões detalhados, etc.), veja `docs/MULTI_AGENT_ORCHESTRATION.md`.

### Qual agente usar

Para tabela completa de qual agente usar para cada tarefa, veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 1, "Quando usar task-build vs. abordagem manual").

 > **Isolamento**: agentes inferiores (`dev`, `code-review`, `task-planner`, `git-commit`) NÃO possuem `permission.task: []` no frontmatter (não suportado pelo parser do OpenCode 1.18.2). Para isolar subagentes, configure `permission.task` no `opencode.json` do projeto.

### Padrões de orquestração

Para padrões detalhados (simples, completo, revisão), veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 3, "Fluxo de Orquestração").

### Regras de delegação

Para regras de delegação detalhadas, veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 5.3, "Regras de Permissão (quem pode chamar quem)").

### Uso de Skills

```bash
# Carregar skill quando tarefa casa com descrição
skill(name="code-reviewer")    # revisão de código
skill(name="systematic-debugging")  # debug de bugs
skill(name="test-master")      # criar testes
skill(name="executing-plans")  # executar plano existente
```

### Loop de trabalho (referência rápida)

Para o workflow detalhado (passos 0–8), veja `task-build.md` e `docs/MULTI_AGENT_ORCHESTRATION.md`.
O loop resumido abaixo cobre os passos essenciais para pipelines orquestrados:

0. Ler AGENTS.md e carregar skills obrigatórias + dinâmicas (SEMPRE)
1. Entender/receber a tarefa do usuário
2. Verificar/criar plano (task-planner, se necessário)
3. Revisão do plano (plan-reviewer) → Gate dinâmico (4c) → Apresentar plano ao usuário
4. Criar feature branch (via git-commit)
5. Para cada task: dev implementa → code-review revisa (individual)
6. Revisão consolidada final (todas as tasks)
7. Commitar (via git-commit) e gerar relatório

> **Regra**: Code review é OBRIGATÓRIO antes de CADA commit (individual + consolidado).
> task-build NUNCA edita arquivos — todas as mudanças são delegadas para dev.

**Notas**
- Este resumo é uma visão de alto nível. Sempre siga o workflow completo em `task-build.md` ao usar o agente `task-build`.
- Para fluxos simples (sem task-build), siga `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 3.2, "Fluxo Simples (sem task-build)").

### Anti-padrões

Para anti-padrões detalhados, veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 9.2).

## Melhorias Recentes

- Migração para OpenCode 1.18.1: agentes em markdown puro (frontmatter YAML com `hidden`, `color`, `temperature`), permissões nativas (`permission.task` — funciona via `opencode.json`, NÃO no frontmatter .md), `plan_enter`/`plan_exit` removidos
- plan-reviewer como skill obrigatória
- Steps 4b/4c no task-build
- Timeouts padronizados (plan-reviewer=3min, code-review 10min/5min)
- Code review explícito antes de cada commit
- 10 novas skills upstream instaladas (devops-engineer, cloud-architect, sql-pro, sre-engineer, monitoring-expert, security-reviewer, debugging-wizard, architecture-designer, terraform-engineer, microservices-architect)
- Criação manual de plano removida (task-build apenas delega)
- Unificação de skills de design/frontend: `design-system-patterns` + `design-tokens` → `design-system`; `frontend-design` + `designing-frontend-interfaces` → `frontend-complete`
- Atualização para OpenCode 1.18.2: subagentes isolados por padrão (`subagent_depth`), `@opencode-ai/plugin` `^1.18.0` → `^1.18.2`
- Atualização para OpenCode 1.18.3: patch de desktop, `@opencode-ai/plugin` `^1.18.2` → `^1.18.3`
- Atualização para OpenCode 1.18.4: Desktop v2 layout, fix subagentes aninhados, `@opencode-ai/plugin` `^1.18.3` → `^1.18.4`
- Atualização para OpenCode 1.18.5: fix Claude adaptive thinking, fix Mistral reasoning/caching, `@opencode-ai/plugin` `^1.18.4` → `^1.18.5`
- Atualização para OpenCode 1.18.10: MCP OAuth/reconnect, legacy MCP compat, `@opencode-ai/plugin` `^1.18.5` → `^1.18.10`
- Atualização para OpenCode 1.18.11: fix MCP SSE reconnect loops, fix provider reasoning fields, `@opencode-ai/plugin` `^1.18.10` → `^1.18.11`
- Atualização para OpenCode 1.18.13: TUI PR context, desktop RTL/i18n, `@opencode-ai/plugin` `^1.18.11` → `^1.18.13`
- Atualização para OpenCode 1.18.15: xAI device-code flow, retry de erros transientes, `@opencode-ai/plugin` `^1.18.13` → `^1.18.15`
- Atualização para OpenCode 1.18.18: config parsing robusto, retry caps, fix Kimi/xAI, `@opencode-ai/plugin` `^1.18.15` → `^1.18.18`
- Stop script melhorado (14/08/2026, dc4f00a): limpeza de órfãos e zumbis por padrão — carrega .env, mata proot zombie-aware, limpa run-cloudflare-tunnel.sh + porta + cloudflared (com porta), nunca pkill -f "opencode web" (risco TUI); validado no device (4 cenários)

Para uma lista completa de melhorias, novidades e decisões recentes, consulte `docs/MULTI_AGENT_ORCHESTRATION.md`.

## Comandos Úteis

```bash
# Execução
opencode_web              # inicia OpenCode Web + tunnel
opencode_web_stop         # para

# Tailscale
opencode_tailscale           # inicia OpenCode Web via Tailscale
opencode_tailscale_stop      # para

# SSH/SFTP
termux_ssh                # inicia sshd + notifica IP
termux_ssh_stop           # para sshd

# Status manual
cat $PREFIX/tmp/opencode_web.pid   # PID
cat $PREFIX/tmp/opencode_url.txt   # URL ativa
cat $PREFIX/tmp/opencode_web.log   # Log de diagnóstico

# Status Tailscale
cat $PREFIX/tmp/opencode_tailscale.pid   # PID
cat $PREFIX/tmp/opencode_tailscale_url.txt   # URL ativa
cat $PREFIX/tmp/opencode_tailscale.log   # Log de diagnóstico
```
