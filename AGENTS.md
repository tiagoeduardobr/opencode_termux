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
│   └── agents/                 ← subagentes (git-commit, code-review)
│       ├── git-commit.md
│       └── code-review.md
├── opencode.json               ← config DO PROJETO (skills path, agents, permissions)
├── bin/
│   ├── opencode-web.sh         ← manager fire-and-forget
│   └── opencode-web-stop.sh    ← stopper
├── run-cloudflare-tunnel.sh    ← script executado dentro do proot
├── shell/
│   └── aliases.sh              ← aliases bash (opencode_web, opencode_web_stop)
├── scripts/
│   └── setup.sh                ← setup em device novo (backup, symlink, npm install)
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
| `NTFY_TOPIC` | `opencode-tunnel` | Tópico ntfy.sh para notificação |
| `PROJECT_DIR` | diretório do script | Onde está `run-cloudflare-tunnel.sh` |
| `NOTIFY_FILE` | `$PREFIX/tmp/opencode_url.txt` | Handoff da URL |
| `PID_FILE` | `$PREFIX/tmp/opencode_web.pid` | PID do processo |

### `run-cloudflare-tunnel.sh`

Executado **dentro do proot** (`--shared-tmp`). Sobe `opencode web` + `cloudflared tunnel` + ntfy push.

## Skills

27 skills instaladas em `.config/opencode/skills/`:

- **Gerais**: api-security-best-practices, backlog-curator, changelog-generator, code-documenter, code-reviewer, coauthoring-docs, content-research-writer, customize-opencode, data-science-expert, designing-frontend-interfaces, documentation-and-adrs, executing-plans, fastapi-expert, frontend-design, javascript-typescript, jupyter-notebook, pandoc-docs, postgres-pro, python-pro, secure-code-guardian, spec-driven-development, staff-engineer-review, systematic-debugging, test-master, web-design-guidelines
- **Projeto-specific** (movidas de `parecer_descritivo/.agents/skills/`): design-system-patterns, design-tokens

Skills usam o caminho relativo `.config/opencode/skills/` no `opencode.json`. O setup.sh garante que `~/.config/opencode/` aponte para cá.

## Dependências (device)

- Termux F-Droid + proot-distro Ubuntu
- Node.js 20+ (dentro do proot)
- `npm install -g @anthropic-ai/opencode`
- cloudflared (dentro do proot)
- curl
- ntfy app (Android, opcional)

## Comandos Úteis

```bash
# Execução
opencode_web              # inicia OpenCode Web + tunnel
opencode_web_stop         # para

# Status manual
cat $PREFIX/tmp/opencode_web.pid   # PID
cat $PREFIX/tmp/opencode_url.txt   # URL ativa
```
