# opencode_termux — Guia para Agentes de IA

Repositório auto-contido que centraliza scripts Termux + config OpenCode global (skills, agents) + setup.sh.

## Estrutura

```
opencode_termux/
├── .config/opencode/           ← GLOBAL (symlink de ~/.config/opencode/)
│   ├── opencode.jsonc          ← config global do opencode
│   ├── package.json            ← dependências de skills (npm)
│   ├── skills/                 ← 27 skills (25 globais + 2 do parecer_descritivo)
│   │   ├── code-reviewer/
│   │   ├── executing-plans/
│   │   ├── design-system-patterns/   ← movido de parecer_descritivo
│   │   ├── design-tokens/            ← movido de parecer_descritivo
│   │   └── ... (23 outras)
│   └── agents/                 ← subagentes (git-commit, code-review, task-planner, dev)
│       ├── git-commit.md
│       ├── code-review.md
│       ├── task-planner.md
│       └── dev.md
├── opencode.json               ← config DO PROJETO (skills path, agents, permissions)
├── bin/
│   ├── opencode-web.sh         ← manager fire-and-forget
│   ├── opencode-web-stop.sh    ← stopper
│   ├── termux-ssh.sh           ← inicia sshd + notifica IP
│   └── termux-ssh-stop.sh      ← para sshd
├── run-cloudflare-tunnel.sh    ← script executado dentro do proot
├── shell/
│   └── aliases.sh              ← aliases bash (opencode_web, opencode_web_stop)
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

```bash
git clone <url> opencode_termux
cd opencode_termux
bash scripts/setup.sh
source shell/aliases.sh        # ou adicionar ao ~/.bashrc
cp .env.example .env           # e editar
```

O `setup.sh`:
1. Faz backup de `~/.config/opencode/` existente (se não for symlink)
2. Cria symlink: `~/.config/opencode/` → `opencode_termux/.config/opencode/`
3. Instala dependências npm do `.config/opencode/`

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

27 skills em `.config/opencode/skills/` (25 globais + 2 movidas de `parecer_descritivo`), além de `customize-opencode` (built-in do opencode, sem diretório).
Subagentes: `git-commit`, `code-review`, `task-planner`, `dev` (prompts em `.config/opencode/agents/`).
Lista completa: `opencode.json` permission.skill e `docs/SESSION_CONTEXT_20260618.md`.

## Dependências (device)

- `npm install -g opencode-ai` (dentro do proot Ubuntu)
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
- **`kill -0`**: Padrão POSIX para testar se processo existe. O stop script faz
  graceful kill (SIGTERM), espera 3s, depois `kill -9`. Não confundir com sinal 0.
- **`stty sane`** no stop: Reset de terminal pós-proot (quirk Termux). Não remover.
- **`termux-notification-remove`** removido: Causa abertura de configurações de bateria
  em MIUI/Xiaomi. A notificação com `--id` e `--ongoing` é limpa automaticamente
  pelo Android quando o processo termina.
  → Detalhes: `docs/termux/termux-notification.md`
- **`.env` loading**: Scripts carregam `.env` de `$SCRIPT_DIR` (raiz do repo), não do CWD.
  `run-cloudflare-tunnel.sh` dentro do proot também carrega do CWD (que é o mesmo dir).
- **`.config/opencode/.gitignore`**: Ignora `node_modules`, `bun.lock` e `.gitignore`
  — intencional (mantém package.json/lock versionados, exclui node_modules).
- **`opencode.json`**: Usa paths relativos `.config/opencode/skills/` e
  `{file:.config/opencode/agents/<name>.md}` para subagentes.
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

## Agent Workflow — Orquestração

### Qual agente usar

| Tarefa | Agente | Quando usar |
|---|---|---|
| Explorar codebase rápido | `explore` | Buscar arquivos, entender estrutura, achar padrões |
| Planejar tarefa antes de implementar | `task-planner` | Gerar plano adaptativo com escopo, dependências e riscos |
| Implementar código | `dev` | Executar tasks do plano com qualidade e conformidade |
| Mudanças simples (1-3 arquivos) | `dev` | Edits, fixes, refactors pontuais |
| Mudanças complexas (3+ arquivos) | `task-planner` → `dev` → `code-review` | Planejar → implementar → revisar |
| Criar commit | `git-commit` | Sempre após mudanças aprovadas |
| Revisão de PR/code | `code-review` | Após implementação, antes de merge |
| Criar skill ou agent | `customize-opencode` | Seguir template do opencode |
| Tarefa com plano escrito | `executing-plans` | Re-executar planos com checkpoints |

### Padrões de orquestração

**Padrão simples** (mudança pontual):
```
1. explore → entender contexto
2. general → implementar
3. git-commit → commitar
```

**Padrão completo** (feature ou fix complexo):
```
1. task-planner → gerar plano adaptativo
2. general → implementar
3. code-review → revisar qualidade
4. git-commit → commitar
```

**Padrão de revisão** (após receber PR/issues):
```
1. code-review → analisar mudanças
2. general → aplicar feedback
3. git-commit → commitar fixes
```

### Regras de delegação

1. **Nunca duplique trabalho** — se delegou para um agente, aguarde o resultado
2. **Encadeie agentes** — passe o resultado de um como contexto do próximo
3. **Use task_id** — para continuar sessão anterior, passe o task_id
4. **Skills primeiro** — antes de implementar, verifique se há skill relevante
5. **Docs antes de código** — sempre leia `docs/` relevante antes de modificar scripts

### Uso de Skills

```bash
# Carregar skill quando tarefa casa com descrição
skill(name="code-reviewer")    # revisão de código
skill(name="systematic-debugging")  # debug de bugs
skill(name="test-master")      # criar testes
skill(name="executing-plans")  # executar plano existente
```

### Loop de trabalho

```
┌─────────────────────────────────────────────────┐
│  1. Entender tarefa                              │
│     └─ explore ou ler contexto                   │
│  2. Planejar (se complexo)                       │
│     └─ task-planner agent                        │
│  3. Implementar                                  │
│     └─ dev agent                                 │
│  4. Verificar                                    │
│     └─ code-review ou rodar tests/lint            │
│  5. Commitar + Push                              │
│     └─ git-commit agent                          │
└─────────────────────────────────────────────────┘
```

### Referências Doc por Fluxo

| Fluxo | Docs para ler |
|---|---|
| **Setup em device novo** | `proot-distro/README.md`, `cloudflare/downloads.md`, `termux/filesystem-layout.md` |
| **Debug do tunnel não subir** | `cloudflare/quick-tunnel.md`, `cloudflare/run-parameters.md` |
| **Mudar porta/host do opencode** | `termux/filesystem-layout.md`, `cloudflare/config-file.md` |
| **Adicionar notificação customizada** | `termux/termux-notification.md` |
| **Atualizar cloudflared** | `cloudflare/downloads.md`, `cloudflare/run-parameters.md` |
| **Migrar de Quick Tunnel para named tunnel** | `cloudflare/config-file.md`, `cloudflare/run-parameters.md` |

### Anti-padrões

- ❌ **Pular explore** → implementar sem entender contexto causa erros
- ❌ **Não usar skill** → re-inventar wheel quando skill já resolve
- ❌ **Commitar sem review** → code quality degrada
- ❌ **Assumir flags** → sempre confirmar na doc local antes de modificar scripts
- ❌ **Não verificar versão** → `cloudflared version`, `proot-distro list` contra doc local

## Comandos Úteis

```bash
# Execução
opencode_web              # inicia OpenCode Web + tunnel
opencode_web_stop         # para

# SSH/SFTP
termux_ssh                # inicia sshd + notifica IP
termux_ssh_stop           # para sshd

# Status manual
cat $PREFIX/tmp/opencode_web.pid   # PID
cat $PREFIX/tmp/opencode_url.txt   # URL ativa
cat $PREFIX/tmp/opencode_web.log   # Log de diagnóstico
```
