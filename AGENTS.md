# opencode_termux — Guia para Agentes de IA

Repositório auto-contido que centraliza scripts Termux + config OpenCode global (skills, agents) + setup.sh.

## Estrutura

```
opencode_termux/
├── .config/opencode/           ← GLOBAL (symlink de ~/.config/opencode/)
│   ├── opencode.jsonc          ← config global do opencode
│   ├── package.json            ← dependências de skills (npm)
│   ├── skills/                 ← 40 skills (26 globais incluindo 2 movidas de parecer_descritivo + 14 do obra/superpowers)
│   │   ├── code-reviewer/
│   │   ├── executing-plans/
│   │   ├── design-system-patterns/   ← movido de parecer_descritivo
│   │   ├── design-tokens/            ← movido de parecer_descritivo
│   │   └── ... (35 outras)
│   └── agents/                 ← subagentes (git-commit, code-review, task-planner, dev, task-build)
│       ├── git-commit.md
│       ├── code-review.md
│       ├── task-planner.md
│       ├── dev.md
│       └── task-build.md
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

40 skills em `.config/opencode/skills/` (26 globais incluindo 2 movidas de `parecer_descritivo` + 14 do obra/superpowers), além de `customize-opencode` (built-in do opencode, sem diretório).
Subagentes: `git-commit`, `code-review`, `task-planner`, `dev`, `task-build` (prompts em `.config/opencode/agents/`).
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
- **RBAC syntax no opencode.json**: O formato correto para permissões de agentes
  é `"agente": "perm"`, não `"perm": ["agente"]`. O formato array é inválido e
  silenciosamente ignorado pelo OpenCode.
  
  **Exemplo correto** (cada subagente nega todos os outros):
  ```json
  "rbac": {
    "task-build": "deny",
    "git-commit": "deny",
    "code-review": "deny",
    "dev": "deny"
  }
  ```
  
  **Exemplo incorreto** (IGNORADO pelo OpenCode):
  ```json
  "rbac": {
    "deny": ["task-build"]
  }
  ```
  
  → Detalhes completos: `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 5.4)
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

> **Visão geral**: Esta seção é um overview rápido dos workflows.
> Para documentação completa (templates, RBAC, circuit breaker, crash recovery,
> anti-padrões detalhados, etc.), veja `docs/MULTI_AGENT_ORCHESTRATION.md`.

### Qual agente usar

Para tabela completa de qual agente usar para cada tarefa, veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção "Qual agente usar").

> **RBAC**: agentes inferiores (`dev`, `code-review`, `task-planner`, `git-commit`) são isolados — cada um nega todos os outros subagentes. Apenas `task-build` pode chamá-los.

### Padrões de orquestração

Para padrões detalhados (simples, completo, revisão), veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção "Padrões de orquestração").

### Regras de delegação

Para regras de delegação detalhadas, veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção "Regras de delegação").

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

1. Ler AGENTS.md e carregar skills obrigatórias + dinâmicas
2. Entender/receber a tarefa do usuário
3. Verificar/criar plano (task-planner, se necessário)
4. Apresentar plano e obter aprovação (gate)
5. Criar feature branch (via git-commit)
6. Para cada task: dev implementa → code-review revisa (individual)
7. Revisão consolidada final (todas as tasks)
8. Commitar (via git-commit) e gerar relatório

> **Regra**: Code review é OBRIGATÓRIO antes de CADA commit (individual + consolidado).
> task-build NUNCA edita arquivos — todas as mudanças são delegadas para dev.

**Notas**
- Este resumo é uma visão de alto nível. Sempre siga o workflow completo em `task-build.md` ao usar o agente `task-build`.
- Para fluxos simples (sem task-build), siga `docs/MULTI_AGENT_ORCHESTRATION.md` (seção "Loop de trabalho").

### Anti-padrões

Para anti-padrões detalhados, veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 9.2).

## Melhorias Recentes

Para uma lista completa de melhorias, novidades e decisões recentes, consulte `docs/MULTI_AGENT_ORCHESTRATION.md`.

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
