# SESSION_CONTEXT — 18/06/2026

## Objetivo

Criar `opencode_termux` como repositório auto-contido centralizando scripts Termux + config OpenCode global (skills, agents) + setup.sh, clonável em qualquer dispositivo Android com Termux.

---

## Constraints & Preferences

- **Ambiente**: Termux (Android 14, arm64, MIUI/Xiaomi) rodando Ubuntu via proot (usuário root)
- **OpenCode Web** exposto via Cloudflare Quick Tunnel (efêmero), notificação via ntfy.sh (curl push)
- **`~/.config/opencode/`** será symlink apontando para `opencode_termux/.config/opencode/`
- **`parecer_descritivo`** consome skills/agents do `opencode_termux` via symlink global (sem alterações no seu `opencode.json`)
- **Plans específicos** do projeto (`parecer_descritivo/.opencode/plans/`) permanecem lá, não no `opencode_termux`
- **Skills de `parecer_descritivo/.agents/skills/`** (design-system-patterns, design-tokens) movidas para `opencode_termux/.config/opencode/skills/` e removidas de `parecer_descritivo`
- **Repositório público** em `https://github.com/tiagoeduardobr/opencode_termux` (push via SSH)
- **`opencode.json`** do `opencode_termux` usa paths relativos (`.config/opencode/...`)
- **Fire-and-Forget**: Manager não gerencia ciclo de vida do proot — só inicia, notifica e sai. Stop por script separado
- **ntfy.sh** como método principal de notificação (termux-notification não funciona no MIUI)

---

## Arquivos Criados

| Path | Descrição |
|---|---|
| `opencode_termux/.config/opencode/agents/code-review.md` | Subagente code-review (movido de `~/.config/opencode/`) |
| `opencode_termux/.config/opencode/agents/git-commit.md` | Subagente git-commit (movido de `~/.config/opencode/`) |
| `opencode_termux/.config/opencode/opencode.jsonc` | Config global do opencode (movido) |
| `opencode_termux/.config/opencode/package.json` | Dependências npm de skills |
| `opencode_termux/.config/opencode/package-lock.json` | Lock file npm |
| `opencode_termux/.config/opencode/skills/` | 27 skills (25 globais + 2 do parecer_descritivo) |
| `opencode_termux/opencode.json` | Config do projeto: skills path, agents, permissions (27 skills allow) |
| `opencode_termux/scripts/setup.sh` | Setup em device novo: backup + symlink + npm install + .bashrc alias |
| `opencode_termux/.env` | Config real: `OPENCODE_PORT=4096`, `NTFY_TOPIC=opencode-tunnel`, `PROJECT_DIR=/root/Projetos/parecer_descritivo` |
| `opencode_termux/docs/SESSION_CONTEXT_20260618.md` | Este arquivo |

## Arquivos Modificados

| Path | O que mudou |
|---|---|
| `opencode_termux/README.md` | Adicionada seção "Estrutura do repositório" com diagrama; tutorial atualizado (setup.sh steps 6-10); arquitetura dividida em 2 camadas (config + execução) |
| `opencode_termux/AGENTS.md` | Expandido de 34 linhas para documento completo com estrutura, arquitetura de config, setup workflow, lista de 27 skills, comandos |
| `opencode_termux/bin/opencode-web.sh` | Inner proot command usa `$SCRIPT_DIR` e `exec ./run-cloudflare-tunnel.sh` (centraliza tunnel script) |
| `opencode_termux/.config/opencode/.gitignore` | Ajustado para tracker package.json/lock |
| `opencode_termux/.gitignore` | `.config/opencode/node_modules/` ignorado |

## Arquivos Removidos

| Path | Motivo |
|---|---|
| `parecer_descritivo/.agents/skills/design-system-patterns/` | Movido para `opencode_termux/.config/opencode/skills/` |
| `parecer_descritivo/.agents/skills/design-tokens/` | Movido para `opencode_termux/.config/opencode/skills/` |
| `parecer_descritivo/run_opencode_web_cloudflare.sh` | Substituído por `opencode_termux/run-cloudflare-tunnel.sh` |

## Commits

### `parecer_descritivo` (branch `main`, pushado via HTTPS)
```
0f3ecd7 chore: remove .agents/skills/ and run_opencode_web_cloudflare.sh
  8 files changed, 2510 deletions(-)
```
Remove `design-system-patterns/`, `design-tokens/`, `run_opencode_web_cloudflare.sh`.

### `opencode_termux` (branch `main`, pushado via SSH)
O repositório foi criado com 2 commits:
```
28d198b feat: initial scaffold for Termux OpenCode Web with Cloudflare Tunnel
a4abb22 feat: centralize opencode config with skills, agents, setup.sh
  61 files changed, 10363 insertions(+), 34 deletions(-)
```

---

## Skills Instaladas (27)

| Skill | Origem |
|---|---|
| `alpine-js` | global |
| `api-security-best-practices` | global |
| `backlog-curator` | global |
| `changelog-generator` | global |
| `coauthoring-docs` | global |
| `code-documenter` | global |
| `code-reviewer` | global |
| `content-research-writer` | global |
| `customize-opencode` | global (built-in) |
| `data-science-expert` | global |
| `design-system-patterns` | parecer_descritivo |
| `design-tokens` | parecer_descritivo |
| `designing-frontend-interfaces` | global |
| `documentation-and-adrs` | global |
| `executing-plans` | global |
| `fastapi-expert` | global |
| `frontend-design` | global |
| `javascript-typescript` | global |
| `jupyter-notebook` | global |
| `pandoc-docs` | global |
| `postgres-pro` | global |
| `python-pro` | global |
| `secure-code-guardian` | global |
| `spec-driven-development` | global |
| `staff-engineer-review` | global |
| `systematic-debugging` | global |
| `test-master` | global |
| `web-design-guidelines` | global |

## Subagentes (2)

| Nome | Prompt |
|---|---|
| `git-commit` | `.config/opencode/agents/git-commit.md` |
| `code-review` | `.config/opencode/agents/code-review.md` |

---

## Pendências (no device real — Termux)

1. **Rodar setup.sh**:
   ```bash
   cd opencode_termux
   bash scripts/setup.sh
   ```
   Cria symlink `~/.config/opencode/` → `opencode_termux/.config/opencode/`, instala npm, adiciona alias ao `.bashrc`.

2. **Remover script obsoleto**:
   ```bash
   rm ~/opencode_web.sh
   ```

3. **Verificar funcionamento**:
   ```bash
   source ~/.bashrc
   opencode_web
   ```

---

## Notas Técnicas

- **cloudflared** v2026.5.2 — URL do Quick Tunnel no stderr, formato `https://XXXX.trycloudflare.com`
- **OpenCode Web**: Ctrl+C não termina (#21505), deixa órfãos (#20899) — Fire-and-Forget contorna
- **`--shared-tmp`** mapeia `/tmp` do proot para `$PREFIX/tmp` do Termux — usado para handoff da URL
- **ntfy.sh** confirmado: `curl -d "msg" ntfy.sh/opencode-tunnel` retorna HTTP 200
- **SSH** usado para push em `opencode_termux` (HTTPS sem credenciais no ambiente Docker); `parecer_descritivo` continua HTTPS
- **`opencode.json`** do `parecer_descritivo` referencia `~/.config/opencode/skills` — não precisa de alteração com o symlink
