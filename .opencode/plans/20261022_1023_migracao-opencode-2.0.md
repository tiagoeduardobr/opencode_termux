# Plano: Migração OpenCode 1.19.3 → 2.0.32 (V2 GA)

## Objetivo

Migrar o repositório `opencode_termux` e o device Termux/proot que o executa do OpenCode **1.19.3 (V1)** para o **2.0.32 (V2 GA)**, preservando a arquitetura de tunnel (Cloudflare Quick Tunnel + Tailscale), os 50 skills, os 5 agentes e as convenções do repositório — com validação **lado a lado** (sem tocar na instalação V1 até o cutover) e rollback testado.

## Escopo

**Dentro:**

- Instalação do V2 GA 2.0.32 (side-by-side → cutover), com degradação segura da sessão TUI ativa.
- Conversão de `opencode.json` (projeto) e `.config/opencode/opencode.jsonc` (global) para o schema V2.
- Adaptação de `run-*.sh` (proot), `bin/*.sh` (Termux) e `scripts/setup.sh`: `opencode web` → `opencode serve`, **senha do servidor**, `opencode pair`, `opencode service`.
- Resolução da dependência órfã `@opencode-ai/plugin` em `.config/opencode/package.json` **e** `.opencode/package.json`.
- Backup e migração do DB `~/.local/share/opencode/opencode.db` (~3,3 GB + WAL ~230 MB).
- Atualização de `AGENTS.md`, `README.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`, `AI_HANDOVER.md`, novo ADR e novo SESSION_CONTEXT.
- Testes E2E no device e procedimento de rollback executável.

**Fora:**

- Conversão nativa completa das configs para o schema V2 (segue como follow-up; mantém-se shape V1 compatível).
- Novas capacidades V2 sem equivalente em V1 (ex.: `opencode pair --remote`/OpenTunnel como canal novo, permissões `ask` granulares) — apenas avaliadas, não implantadas.
- Mudanças de produto pendentes no V1 (ex.: Tailwind v4) — não são pré-requisito desta migração.
- Reescrita do conteúdo das 50 skills / 5 agentes — apenas validação de compatibilidade e correções mínima.

## Premissas

1. Escopo completo: CLI/instalação, config, scripts, plugin e docs.
2. Validar o V2 lado a lado antes do cutover; o V1 1.19.3 permanece instalado e funcional como fallback até o corte.
3. Manter shapes V1 de config; conversão nativa V2 fica como follow-up.
4. A premissa original de reescrever `{action: external_directory, resource: "*", effect: "ask"}` **está errada**: essa regra **NÃO existe** no `opencode.json` deste repo (verificado em 08/11/2026). Não há nada a reescrever; a conversão nativa V2 fica como follow-up da T16.
5. Sem PR: branch local + merge fast-forward em `main`.
6. O usuário aceita mudança no formato das URLs de acesso (V2 exige senha no servidor).

## Contexto factual (verificado empiricamente em 22/10/2026)

### V1 — estado atual

- Binário V1: `/usr/bin/opencode` → symlink para `/data/data/com.termux/files/usr/lib/node_modules/opencode-linux-arm64/bin/opencode` (npm global **do Termux**, o proot só expõe via bind). Versão `1.19.3`.
- Serviço **V1 ativo neste device**: `opencode web --hostname 127.0.0.1 --port 4096` (PID 30104, rodando há ~5 h).
- Config global: `~/.config/opencode` → symlink para `/root/Projetos/opencode_termux/.config/opencode/` (50 skills + 5 agentes).
- `opencode.json` (projeto) usa shape V1: `model`, `skills.paths`, `permission.skill`.
- `.config/opencode/opencode.jsonc` contém apenas `{"$schema": ...}`.
- Dependências: `.config/opencode/package.json` → `@opencode-ai/plugin: ^1.19.3`; `.opencode/package.json` → `@opencode-ai/plugin: 1.17.9` (divergente). **Nenhuma fonte de plugin, nenhuma pasta de plugin e nenhuma chave `plugin` nas configs** → dependência órfã nas duas árvores.
- Dados: `~/.local/share/opencode` ≈ **3,4 GB**; `opencode.db` ≈ 3,1 GB (3.268.820.992 B em 08/11/2026; cresce com o uso); WAL ≈ 230 MB; cache ≈ 11 MB.
- `scripts/setup.sh` **não instala** o binário do opencode (apenas `npm install` em `.config/opencode` e imprime a versão detectada). A instalação é documentada no `AGENTS.md` (`npm install -g opencode-linux-arm64 --force`).

### V2 2.0.32 — pacotes

- `@opencode/cli@2.0.32` → `bin: { "opencode": "bin/opencode.exe", "opencode2": "bin/opencode.exe" }` (mesmo binário, dois nomes).
- Optional dep arm64: `@opencode/cli-linux-arm64@2.0.32` (58 MB comprimido; binário ≈ 198 MiB / 207.472.936 B; prefixo instalado ≈ 199 MB).
- Canal beta `@opencode-ai/cli@next` → `0.0.0-beta-17823` (bin `opencode2` apenas). **É mais antigo que o GA** e não tem `debug paths` — não serve como canal de validação do GA.
- **Risco de versão:** `@opencode/cli@latest` já está em **2.2.6** (verificado em 08/11/2026; era 2.1.3 em 22/10/2026), não 2.0.32. Fixar `2.0.32` explicitamente; nunca usar `@latest` sem versão.

### V2 2.0.32 — CLI (verificado com o binário arm64 em `/tmp/opencode/v2inspect/`)

- `opencode web` **removido** → substituto: `opencode serve --hostname <host> --port <port>` ("Start the v2 API and web server").
- `opencode serve` **não aceita** `--standalone` (erro: `Unrecognized flag: --standalone in command opencode serve`); `run` e `api` aceitam `--standalone` e `--server`.
- `opencode db` **removido** → `bin/limpar-opencode.sh` quebra.
- `opencode debug agent <n>` → `opencode debug agents` (plural). `debug config` e `debug paths` existem (o `debug paths` não existe no beta antigo).
- `opencode upgrade <target>` (sem `--major`); `service start|restart|status`; `pair`; `run`; `api`; `stats`; `models`; `mcp`; `plugin`; `session list|delete|export`; `auth list|login|logout|export|import|switch`; `acp`; `mini`.
- `debug config` do V2 também varre `/root/.agents` (nossos skills de RN/Expo) como fonte de agentes.

### V2 2.0.32 — segurança do servidor (impacto crítico nos scripts)

- `opencode serve` imprime `server listening on http://<host>:<port>` e, se `OPENCODE_PASSWORD` **não** estiver setado, imprime `server password <senha aleatória de 32 bytes>`.
- Sem `OPENCODE_PASSWORD`, a senha é **aleatória a cada start** → precisa ser capturada e entregue ao usuário.
- **API base path = `/api/*`** (JSON). Rota **inexistente sob `/api/*` → 404** (corpo vazio ou JSON de erro), **nunca** cai no SPA; fora de `/api/*`, qualquer path → **200 text/html** (fallback do SPA). Logo, health-check por status HTTP não é confiável: usar rota **conhecida** (`/api/agent`) **e** validar `content-type: application/json` — status HTTP sozinho não basta.
- **Autenticação: HTTP Basic com usuário fixo `opencode`** e a senha do servidor.
  - Sem credencial → `401 {"_tag":"UnauthorizedError","message":"Authentication required"}`.
  - `Authorization: Bearer <senha>` → **401** (não suportado).
- `opencode pair [--url <url>] [--remote] [--yes]` imprime links one-time; `--remote` expõe via OpenTunnel com criptografia E2E.

### V2 2.0.32 — banco de dados (impacto crítico nos dados)

- Caminho do DB (código extraído do binário): `OPENCODE_DB` (precedência máxima) → senão, se o canal ∈ `{latest, dev, beta, next, prod}` ou `OPENCODE_DISABLE_CHANNEL_DB=1|true` → **`opencode.db`**; senão → `opencode-<canal>.db`.
- **Verificado empiricamente:** o GA 2.0.32 e o beta 0.0.0-beta-17823 **ambos criam `opencode.db`** — o **mesmo caminho do V1** (`~/.local/share/opencode/opencode.db`). Não há isolamento de canal por padrão.
- Existe no código uma migração V1→V2 que lê um DB "next" (`opencode-next.db` por padrão, sobrescrevível via `nextDatabasePath`) e copia sessões V1 (`session`, `message`, `part`) para as tabelas V2 (`session_message`) em fases ("Migrating sessions").
- **Consequência:** rodar o V2 sobre a instalação real pode **alterar/migrar o DB do V1**, quebrando o fallback. Isolamento obrigatório via `OPENCODE_DB` até o cutover.

### V2 2.0.32 — serviço em background (impacto crítico na arquitetura)

- O V2 usa **servidor de background compartilhado**: executar apenas `opencode2 debug config` no beta **já autostartou `opencode2 serve --service`** (PID observado). Clientes (`run`, `api`, TUI) conectam-se a esse serviço.
- `opencode serve --service` é o modo "serviço"; `opencode service start|restart|status` gerencia o ciclo de vida.
- O `serve` standalone (fora do serviço compartilhado) **não** serve as requisições do cliente: a API só responde no processo `serve` que está em foreground.

## Dependências

### Matriz de Dependências

| Tarefa | Depende de | Premissa |
|--------|-----------|----------|
| T1 Backup do ambiente V1 | — | Nada precisa existir ainda; é o pré-requisito de tudo |
| T2 Notas de breaking changes (docs) | — | Consolida o levantamento já feito nesta investigação |
| T3 Instalar V2 2.0.32 isolado | T1 | Backup precisa existir antes de tocar em `/usr/bin` e no npm global do Termux |
| T4 PoC V2 isolado | T3, T1 | Binário instalado + backup para testar `OPENCODE_DB` sem tocar no DB real |
| T5 Config global V2 (`opencode.jsonc`) | T2 | Decisões de breaking change documentadas |
| T6 Config do projeto V2 (`opencode.json`) | T2, T5 | Schema e regras de permissão definidos antes do schema do projeto |
| T7 Validar agents + skills no V2 | T4, T5, T6 | V2 rodando com as configs convertidas |
| T8 `run-*.sh` (launchers do proot) | T4 | Precisa saber a senha: `OPENCODE_PASSWORD` e a flag `serve` |
| T9 `bin/opencode-*.sh` (wrappers Termux) | T8 | Wrappers consomem a URL/senha geradas pelos launchers |
| T10 Stop scripts (`bin/*-stop.sh`) | T8, T9 | Precisam parar o `serve` do V2 e o serviço compartilhado sem `pkill -f "opencode web"` |
| T11 `bin/limpar-opencode.sh` | T4 | `opencode db` não existe no V2 |
| T12 `scripts/setup.sh` | T3 | Precisa conhecer o novo método de instalação |
| T13 Plugin (decisão + limpeza) | T7 | Só decidir após validar o que o V2 espera de plugins |
| T14 Docs principais (`AGENTS.md`, `README.md`) | T8, T9, T10, T11, T12 | Descrevem o comportamento real já implementado |
| T15 Docs de orquestração (`MULTI_AGENT_ORCHESTRATION.md`, `AI_HANDOVER.md`) | T7, T14 | Precisam do inventário de agentes/skills validado |
| T16 ADR + índice de ADRs | T14, T15 | Registra as decisões já materializadas |
| T17 Cutover V1→V2 | T3, T4, T6, T7, T10, T13, T14 | Só após tudo validado isolado e documentado |
| T18 E2E no device | T17 | Só faz sentido no cutover |
| T19 Rollback testado | T17, T18 | Precisa do cutover feito para poder reverter |
| T20 Índice de planos + SESSION_CONTEXT | T16, T19 | Fechamento documental |

### Pré-requisitos

- Backup completo de `~/.local/share/opencode` (DB + WAL), `~/.config/opencode`, `~/.local/share/opencode/auth.json` e `account.json`.
- ~4 GB livres no `/data/data/com.termux/files/usr` (prefixo isolado do V2 ≈ 199 MB + cópia do DB ≈ 3,3 GB).
- Acesso ao registry npm (`@opencode/cli@2.0.32` já baixado e validado em `/tmp/opencode/v2inspect/`).
- Sessão TUI ativa identificada: reiniciar o TUI é obrigatório em qualquer fase (o `run-cloudflare-tunnel.sh` é filho do TUI e morre junto).

### Ordem de Implementação

`T1 → T2 → T3 → T4 → T5 → T6 → T7 → (T8 → T9 → T10) , (T11), (T12), (T13) → T14 → T15 → T16 → T17 → T18 → T19 → T20`

Tarefas paralelizáveis: `T8`, `T11`, `T12` e `T13` podem ser executadas em paralelo após `T7`.

## Tasks

### Checkpoint 0: Ambiente seguro e evidência registrada

### T1 — Backup integral do ambiente V1

- [x] **Status:** concluído em [08/11/2026:00:41]
- **Depende de:** —
- **Arquivos:** `/data/data/com.termux/files/usr/tmp/opencode-v1-backup-20261108_0017/` (+ cópia durável em `/root/backups/opencode-v1-backup-20261108_0017/`)
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given o V1 rodando com ~3,1 GB de `opencode.db` em `~/.local/share/opencode/`, When a T1 é executada, Then existe uma cópia verbatim de `opencode.db`, `opencode.db-wal`, `opencode.db-shm`, `auth.json` e `account.json` num diretório de backup com checksum SHA-256 registrado.
- Given o diretório global `~/.config/opencode` (symlink para o repo), When a T1 é executada, Then existe um tarball do conteúdo resolvido de `.config/opencode/` (skills + agents + jsonc + package.json), sem seguir o symlink como link.

**Verification:**

- **Run:** `ls -lh /data/data/com.termux/files/usr/tmp/opencode-v1-backup-*/ && sha256sum /data/data/com.termux/files/usr/tmp/opencode-v1-backup-*/opencode.db | tee /data/data/com.termux/files/usr/tmp/opencode-v1-backup-*/opencode.db.sha256`
- **Expected:** arquivos `opencode.db` (~3,1 GB / 3.268.820.992 B), `opencode.db-wal` (~230 MB), `auth.json`, `account.json`, `config.tar.gz` presentes; checksum SHA-256 impresso e o arquivo `opencode.db.sha256` criado no diretório de backup.

### T2 — Consolidar as notas de breaking changes V1→V2

- [x] **Status:** concluído em [08/11/2026:01:42]
- **Depende de:** —
- **Arquivos:** `docs/opencode-v2-migration-notes.md` (novo)
- **Complexidade:** baixa

**Acceptance (Given/When/Then):**

- Given o levantamento empirico já feito (CLI, auth, DB, serviço compartilhado), When a T2 é executada, Then `docs/opencode-v2-migration-notes.md` documenta, com o comando que comprova cada um: remoção de `web`/`db`, `debug agent`→`debug agents`, API em `/api/*`, Basic auth `opencode:<senha>`, `OPENCODE_PASSWORD`, colisão de DB `opencode.db` nos 3 canais, autostart do `serve --service` e o fato de `latest` = 2.2.6 (2.1.3 em 22/10/2026).
- Given a nota de migração, When um leitor sem contexto busca "como o V2 exige senha do servidor", Then encontra a resposta com o trecho de código-fonte extraído do binário que a comprova.

**Verification:**

- **Run:** `grep -nE "OPENCODE_PASSWORD|opencode\.db|/api/|debug agents|2\.1\.3" docs/opencode-v2-migration-notes.md`
- **Expected:** pelo menos 8 linhas correspondentes, uma por item de breaking change, todas com o comando de verificação associado.

### T3 — Instalar o V2 2.0.32 em prefixo isolado (sem colisão com o V1)

- [x] **Status:** concluído em [08/11/2026:11:44]
- **Depende de:** T1
- **Arquivos:** `/data/data/com.termux/files/usr/opt/opencode-v2/` (novo, fora do repo); `/usr/local/bin/opencode2` (symlink no proot)
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given o V1 instalado em `/data/data/com.termux/files/usr/lib/node_modules/opencode-linux-arm64` com bin `opencode`, When a T3 é executada, Then `opencode --version` continua retornando `1.19.3` e `opencode2 --version` retorna `2.0.32`, sem sobrescrever o binário V1.
- Given o prefixo isolado, When a T3 é executada, Then `npm ls --prefix <prefixo> @opencode/cli` mostra exatamente `2.0.32` e `npm view @opencode/cli@latest version` (2.2.6) **não** foi usado.

**Verification:**

- **Run:** `opencode --version; opencode2 --version; npm ls --prefix /data/data/com.termux/files/usr/opt/opencode-v2 --depth=0`
- **Expected:** `1.19.3` e `2.0.32` em linhas distintas; `@opencode/cli@2.0.32` listado como dependência direta, sem `2.2.6` (a versão de `@latest`).

### Receita de instalação no Termux/proot (obrigatória)

```bash
PREFIXO=/data/data/com.termux/files/usr/opt/opencode-v2
SHIM="$PREFIXO/.termux-os-linux-shim.cjs"
mkdir -p "$PREFIXO"

# 1) Shim: o postinstall de @opencode/cli usa os.platform() e o Node do Termux reporta "android".
#    O shim precisa existir ANTES do primeiro install.
printf '%s\n' 'const os = require("node:os")' 'os.platform = () => "linux"' > "$SHIM"

# 2) Install: --force é obrigatório (npm-install-checks usa process.platform === "android" → EBADPLATFORM);
#    a dep arm64 precisa ser pedida explicitamente (npm ignora --force para optionalDependencies).
#    NODE_OPTIONS é ESCOPO A ESTA INVOCAÇÃO — nunca exportar globalmente.
NODE_OPTIONS="--require $SHIM" npm install --force --prefix "$PREFIXO" \
  @opencode/cli@2.0.32 @opencode/cli-linux-arm64@2.0.32

# 3) Symlink: SOMENTE opencode2 (o pacote também publica "opencode" e sombrearia o V1 no PATH)
ln -sf "$PREFIXO/node_modules/.bin/opencode2" /usr/local/bin/opencode2
```

**Nunca** `export NODE_OPTIONS=...` no setup.sh/.bashrc: o shim faz monkeypatch global de `os.platform` e faria todo processo Node do device reportar `linux`, mascarando o gate EBADPLATFORM do npm.

### Checkpoint 1: V2 instalado lado a lado

- **Verificar:** V1 e V2 coexistem, com versões distintas e sem colisão de bin.
- **Validação:** `opencode --version && opencode2 --version` → `1.19.3` e `2.0.32`.

### T4 — PoC funcional do V2 com DB e senha isolados

- [x] **Status:** concluído em [08/11/2026:15:10]
- **Depende de:** T3, T1
- **Arquivos:** nenhum (PoC); artefatos em `/data/data/com.termux/files/usr/tmp/v2poc/`
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given `OPENCODE_DB` apontando para um arquivo vazio isolado, When `opencode2 serve --hostname 127.0.0.1 --port 4097` é executado, Then o arquivo de DB criado fica no caminho isolado e o processo V2 **não tem NENHUM fd** para `~/.local/share/opencode/opencode.db` (verificado via `/proc/<pid>/fd`) — tem fds **apenas** para `$OPENCODE_DB{,-wal,-shm}`.
- Given o mesmo PoC, When se inspeciona `/proc/<pid>/fd`, Then o log do V2 aparece como fd para `~/.local/share/opencode/log/opencode.log` (**mesmo inode** do log do V1) — `OPENCODE_DB` isola o **DB**, **não** o log.
- Given `OPENCODE_PASSWORD=senha-de-teste-123`, When `curl -u opencode:senha-de-teste-123 http://127.0.0.1:4097/api/agent` é executado, Then a resposta é JSON HTTP 200; e sem `-u`, Then é HTTP 401 com `UnauthorizedError`.
- Given o `serve` do V2 rodando, When `opencode2 api --server http://127.0.0.1:4097 GET /api/agent` é executado, Then retorna JSON (sem `UnauthorizedError`), provando que `OPENCODE_PASSWORD` satisfaz o cliente oficial.

**Verification:**

- **Run:** `mkdir -p /data/data/com.termux/files/usr/tmp/v2poc; OPENCODE_DB=/data/data/com.termux/files/usr/tmp/v2poc/test.db OPENCODE_PASSWORD=senha-de-teste-123 opencode2 serve --hostname 127.0.0.1 --port 4097 & PID=$!; sleep 12; ls -l /proc/$PID/fd | grep -E "opencode.*\.db"; curl -s -o /dev/null -w '%{http_code}\n' -u opencode:senha-de-teste-123 http://127.0.0.1:4097/api/agent; curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:4097/api/agent; kill "$PID"; wait "$PID"; opencode2 service stop`
- **Expected:** `200` e `401` nessa ordem; os fds de DB listados são **apenas** `$OPENCODE_DB{,-wal,-shm}` (nenhum `~/.local/share/opencode/opencode.db`); o cleanup é **obrigatório** (`kill "$PID"; wait "$PID"; opencode2 service stop`) e deixa `0` processos V2 residuais.

### Checkpoint 2: PoC validado — DB real intocado

- **Verificar:** o DB do V1 não foi tocado pelo PoC do V2.
- **Validação:** inspecionar `/proc/<pid>/fd` do processo V2 — **nenhum** fd para `~/.local/share/opencode/opencode.db`; fds apenas para `$OPENCODE_DB{,-wal,-shm}`.

### T5 — Validar a config global (shape V1 mantido) sob o V2

- [x] **Status:** concluído em [08/11/2026:19:31]
- **Depende de:** T2
- **Arquivos:** `.config/opencode/opencode.jsonc`
- **Complexidade:** baixa

**Acceptance (Given/When/Then):**

- Given a config global atual usa shape V1 (`mcp` como objeto, `RENDER_API_KEY` como `{env:RENDER_API_KEY}`), When a T5 é executada, Then o arquivo **mantém o shape V1** (o V1 1.19.3 está em produção e lê os mesmos arquivos — converter `mcp` → `mcp.servers` quebraria o V1) e **não** ganha paths absolutos de skills (a autodescoberta de `~/.config/opencode/skills` já cobre).
- Given a config global mantida em shape V1, When `opencode2 debug config` é executado, Then a saída lista a config global do repositório (`/root/.config/opencode/opencode.jsonc`) **e** a config do projeto (`/root/Projetos/opencode_termux/opencode.json`), o servidor MCP `render` aparece configurado (traduzido pelo V2 para `mcp.servers`), e **nenhum aviso de schema desconhecido** é emitido.
- Given a config global dual-compatible, When `opencode debug config` (V1) é executado, Then o mesmo arquivo é lido sem erro e o servidor MCP `render` aparece com o mesmo shape (`mcp.render`).

**Verification:**

- **Run:** `mkdir -p /data/data/com.termux/files/usr/tmp/v2poc; OPENCODE_DB=/data/data/com.termux/files/usr/tmp/v2poc/test.db opencode2 debug config | grep -nE "opencode.jsonc|opencode_termux/opencode.json|\"render\"|\"servers\""`; `opencode debug config | grep -nE "\"render\""`
- **Expected:** exit code 0; a config global do repo e a do projeto listadas; o servidor MCP `render` presente nas duas saídas; nenhum aviso em stderr.

### T6 — Validar a config do projeto (shape V1 mantido) sob o V2

- [x] **Status:** concluído em [08/11/2026:19:31]
- **Depende de:** T2, T5
- **Arquivos:** `opencode.json`
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given o `opencode.json` usa shape V1 (`permission.skill`, `skills.paths`, `model`), When a T6 é executada, Then o arquivo **mantém o shape V1** (o V1 1.19.3 está em produção e lê os mesmos arquivos — converter para o shape nativo V2 quebraria as permissões de skill do V1).
- Given o shape V1 mantido, When `opencode2 debug config` é executado, Then o V2 interpreta corretamente: `model` → `{providerID, model}`, `skills.paths` → `skills`, `permission.skill` → array `permissions` com 50 entradas `{action: "skill", resource: "<nome>", effect: "allow"}`, e **nenhum aviso de schema desconhecido** é emitido.
- Given a regra `external_directory`, When a T6 é executada, Then fica registrado que essa regra **NÃO existe** no `opencode.json` deste repo (a premissa original do plano estava errada) e que a conversão nativa V2 fica como **follow-up** da T16.
- Given uma config dual-compatible, When `opencode debug config` (V1) é executado, Then a saída efetiva é equivalente: `model: opencode/big-pickle`, `skills.paths: [".config/opencode/skills"]` e 50 entradas em `permission.skill` com `allow`.

**Verification:**

- **Run:** `mkdir -p /data/data/com.termux/files/usr/tmp/v2poc; OPENCODE_DB=/data/data/com.termux/files/usr/tmp/v2poc/test.db opencode2 debug config | grep -c '"action": "skill"'` → `50`; `opencode debug config > /tmp/v1-config.json && python3 -c "import json; print(len(json.load(open('/tmp/v1-config.json'))['permission']['skill']))"` → `50`; `grep -nE '"permission"|"skills"|"model"' opencode.json`
- **Expected:** exit code 0; `50` permissões de skill traduzidas pelo V2 e `50` no V1 (equivalência); o arquivo do projeto **inalterado** no shape V1 (`permission.skill`, `skills.paths`, `model`).
- **Nota:** a saída do `opencode debug config` (V1) é **truncada quando encadeada por pipe** — redirecionar para arquivo antes de parsear com `python3`/`jq`.

### T7 — Validar agentes e skills sob o V2

- [x] **Status:** concluído em [08/11/2026:21:21]
- **Depende de:** T4, T5, T6
- **Arquivos:** `.config/opencode/agents/*.md`, `.config/opencode/skills/**/SKILL.md` (somente correções de compat, se houver)
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given os 5 agentes e 50 skills instalados, When `opencode2 debug agents` é executado, Then a lista inclui `build`, `plan`, `task-build`, `task-planner`, `dev`, `code-review`, `git-commit` com `mode` e `permission` preenchidos.
- Given os 50 skills, When `opencode2 debug agents`/`debug config` são executados, Then nenhum skill aparece quebrado (frontmatter inválido) e a lista de skills continua com 50 entradas.
- Given a config do projeto convertida, When um comando não autorizado é simulado, Then a permissão é avaliada conforme o array `permissions` do V2 (não há bypass silencioso).

**Verification:**

- **Run (skills — servidor isolado, `OPENCODE_DB` prefixado):**

  ```bash
  mkdir -p /data/data/com.termux/files/usr/tmp/v2poc
  OPENCODE_DB=/data/data/com.termux/files/usr/tmp/v2poc/test.db OPENCODE_PASSWORD=senha-de-teste-123 \
    opencode2 serve --hostname 127.0.0.1 --port 4097 > /data/data/com.termux/files/usr/tmp/v2poc/serve.log 2>&1 &
  PID=$!
  for i in 1 2 3 4 5; do
    curl -s -u opencode:senha-de-teste-123 http://127.0.0.1:4097/api/skill > /data/data/com.termux/files/usr/tmp/v2poc/skill.json
    [ "$(grep -c '"id":' /data/data/com.termux/files/usr/tmp/v2poc/skill.json)" -ge 91 ] && break
    sleep 3
  done
  grep -c '"id":' /data/data/com.termux/files/usr/tmp/v2poc/skill.json   # esperado: 91 (50 do repo + 41 externas/built-in)
  kill "$PID"; wait "$PID" 2>/dev/null
  opencode2 service stop
  rm -f /root/.config/opencode/service.json
  ```

- **Run (agentes — `OPENCODE_DB` prefixado por invocação):**

  ```bash
  mkdir -p /data/data/com.termux/files/usr/tmp/v2poc
  OPENCODE_DB=/data/data/com.termux/files/usr/tmp/v2poc/test.db opencode2 debug agents | grep -c '"name"'
  # cleanup obrigatório (o serviço compartilhado persiste):
  opencode2 service stop
  rm -f /root/.config/opencode/service.json
  ```

- **Expected:** `91` skills no estado estável (50 do repo + 39 externas + 2 built-in do V2 `OpenCode`/`Report`; no V1 são 90, com `customize-opencode` no lugar de `OpenCode`); contagem de agentes ≥ 7 (5 do repo + `build`/`plan` nativos); os 3 agentes de orquestração presentes com `permission` não vazio. A 1ª requisição pode vir vazia (cold start) — por isso o retry no laço acima.
- **Nota:** `OPENCODE_DB` deve ser SEMPRE prefixado por invocação — nunca exportado no shell/`.env` (ver FIX-4).

### Checkpoint 3: Configs convertidas e agentes/skills validados

- **Verificar:** V2 carrega as configs do projeto e globais sem erro e enxerga os 5 agentes + 50 skills.
- **Validação:** `opencode2 debug agents` e `opencode2 debug config` sem warnings.

### T8 — Migrar os launchers do proot (`web` → `serve` + senha)

- [ ] **Status:** pendente
- **Depende de:** T4
- **Arquivos:** `run-cloudflare-tunnel.sh`, `run-opencode-tailscale.sh`
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given os launchers hoje executam `opencode web --hostname 127.0.0.1 --port 4096`, When a T8 é executada, Then ambos executam `opencode serve --hostname 127.0.0.1 --port 4096` mantendo o `exec` (nunca `bash -c` sem `exec`) e o `--shared-tmp`.
- Given o V2 exige senha, When o launcher sobe o servidor, Then ele **não** lê a senha do `.env` (o `.env` é versionado e **não** recebe a senha): a senha é gerada/persistente em `$PREFIX/tmp/opencode_password.txt` (chmod 600) e lida dali, **antes** de iniciar o `serve`, de modo que a senha seja estável entre reinícios e recuperável.
- Given a senha é obrigatória na API, When o launcher monta a URL/arquivo de handoff, Then ele também persiste a senha em arquivo de handoff (ex.: `$PREFIX/tmp/opencode_password.txt`) para o script de notificação.
- Given o launcher usa `.env`, When a T8 é executada, Then o `.env` continua sendo carregado por `$SCRIPT_DIR` (raiz do repo) e não pelo CWD.

**Verification:**

- **Run:** `grep -nE "opencode (web|serve)|OPENCODE_PASSWORD" run-cloudflare-tunnel.sh run-opencode-tailscale.sh; grep -n "exec ./run-" bin/opencode-web.sh bin/opencode-tailscale.sh`
- **Expected:** zero ocorrências de `opencode web`; presença de `opencode serve` e `OPENCODE_PASSWORD` nos dois `run-*.sh`; o `exec ./run-*` preservado nos dois wrappers (`bin/opencode-*.sh`).

### T9 — Migrar os wrappers Termux (URL, senha na notificação, ntfy)

- [ ] **Status:** pendente
- **Depende de:** T8
- **Arquivos:** `bin/opencode-web.sh`, `bin/opencode-tailscale.sh`
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given o V2 exibe a senha do servidor, When o wrapper monta a mensagem de notificação ntfy, Then ela inclui a URL **e** a senha de acesso (ou o link one-time gerado por `opencode2 pair --url <url>`), porque só a URL não autentica mais.
- Given o wrapper lê o handoff, When o arquivo `opencode_url.txt` é lido, Then o wrapper também lê o arquivo de senha e o entrega ao usuário.
- Given a convenção `fire-and-forget` (o `opencode` tem bug de Ctrl+C, #21505), When a T9 é executada, Then o wrapper mantém `disown` + PID file e **não** passa a gerenciar o `serve` em foreground dentro do proot de forma diferente do modelo atual.

**Verification:**

- **Run:** `grep -nE "password|pair|NTFY|disown" bin/opencode-web.sh bin/opencode-tailscale.sh`
- **Expected:** ambos os wrappers referenciam a senha/`pair` e mantêm `disown` + PID file.

### T10 — Migrar os stop scripts (limpeza sem `pkill -f "opencode web"`)

- [ ] **Status:** pendente
- **Depende de:** T8, T9
- **Arquivos:** `bin/opencode-web-stop.sh`, `bin/opencode-tailscale-stop.sh`
- **Complexidade:** alta

**Acceptance (Given/When/Then):**

- Given o V2 introduz o serviço compartilhado (`opencode service`), When o stop script é executado, Then ele encerra o processo `serve` do V2 **e** o serviço compartilhado do V2, sem `pkill -f "opencode web"` (que mataria o TUI).
- Given o serviço compartilhado do V2 roda como `/.l2s/.l2s.opencode0001.0002 serve --service` (proot com `--link2symlink`), When o stop script procura processos residuais, Then ele usa o padrão `ps -eo pid,args | grep -cE "[s]erve --service|[o]pencode2 serve"` (esperado `0`) — o cmdline do serviço compartilhado **NÃO casa** com `opencode serve` nem com `opencode2`, logo um grep por esses nomes reportaria `0` falsos e deixaria o serviço vivo.
- Given o serviço compartilhado do V2, When o stop script é executado, Then o comando canônico de parada é `opencode2 service stop` (não `kill` por PID), seguido da remoção de `rm -f "$CONFIG_DIR/service.json"` — o `service stop` **não** remove esse arquivo, e ele contém a senha do serviço em texto claro dentro do repo (via symlink `~/.config/opencode`).
- Given a regra do ADR-009 (kill graceful → kill -9 → cleanup de órfãos/zumbis com `is_zombie()`), When a T10 é executada, Then a ordem e a checagem de zumbi são preservadas, e `stty sane` continua no final.
- Given o `opencode` do Termux é filho do TUI, When o stop script varre processos, Then ele identifica o processo por PID file e/ou por caminho do binário, nunca por string genérica do comando.

**Verification:**

- **Run:** `grep -nE "pkill|service|is_zombie|stty sane|kill -0" bin/opencode-web-stop.sh bin/opencode-tailscale-stop.sh; ps -eo pid,args | grep -cE "[s]erve --service|[o]pencode2 serve"`
- **Expected:** zero ocorrências de `pkill -f "opencode web"`; presença de `is_zombie`, `stty sane`, do tratamento de `opencode service` (`opencode2 service stop`) e da remoção de `service.json`; a contagem de processos residuais é `0`.

### T11 — Migrar `bin/limpar-opencode.sh` (sem `opencode db`)

- [ ] **Status:** pendente
- **Depende de:** T4
- **Arquivos:** `bin/limpar-opencode.sh`
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given `opencode db` foi removido no V2, When a T11 é executada, Then o script para de invocar `opencode db` e passa a limpar o DB por remoção do arquivo (com o serviço parado), **preservando** `auth.json` e `account.json`.
- Given o script valida o ambiente com um comando de teste, When o comando é reescrito, Then ele usa um subcomando que existe no V2 (ex.: `opencode2 stats` ou `opencode2 api`) e falha com mensagem clara se a versão for < 2.

**Verification:**

- **Run:** `grep -nE "opencode2? db|auth\.json|account\.json|stats|api" bin/limpar-opencode.sh`
- **Expected:** zero ocorrências de `opencode db`; presença de guarda de `auth.json`/`account.json` e de um subcomando V2 válido.

### T12 — Migrar `scripts/setup.sh` (instalação do V2)

- [ ] **Status:** pendente
- **Depende de:** T3
- **Arquivos:** `scripts/setup.sh`
- **Complexidade:** baixa

**Acceptance (Given/When/Then):**

- Given o setup hoje só detecta a versão do opencode instalado, When a T12 é executada, Then ele passa a **instalar** o V2 na versão fixada `2.0.32` (prefixo isolado ou global, conforme a decisão do cutover), sem `@latest`, e imprime a versão detectada ao final.
- Given o setup roda em device novo, When a T12 é executada, Then ele mantém o symlink de `~/.config/opencode` e o `npm install` em `.config/opencode` funcionando como antes, e **não** apaga o `auth.json`/`account.json` do usuário.

**Verification:**

- **Run:** `grep -nE "@opencode/cli@2\.0\.32|opencode2|CONFIG_LINK|npm install" scripts/setup.sh`
- **Expected:** versão fixada `2.0.32` presente (sem `latest`), symlink e `npm install` preservados.

### T13 — Decidir e tratar a dependência de plugin órfã

- [ ] **Status:** pendente
- **Depende de:** T7
- **Arquivos:** `.config/opencode/package.json`, `.opencode/package.json`
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given que não existe nenhuma fonte de plugin no repositório e nenhuma chave `plugin` nas configs, When a T13 é executada, Then a decisão está registrada em ADR (remover a dependência **ou** implementar o plugin) e os dois `package.json` ficam coerentes entre si (mesma versão do `@opencode-ai/plugin`, ou ambos removidos).
- Given a dependência é mantida, When `npm install` roda em `.config/opencode`, Then a versão do plugin é compatível com o runtime do V2 e o `package-lock.json` é atualizado.

**Verification:**

- **Run:** `cat .config/opencode/package.json .opencode/package.json | grep -n "@opencode-ai/plugin"; git diff --stat`
- **Expected:** as duas árvores declaram a mesma versão (ou nenhuma), e o diff mostra apenas os arquivos de package manifest/lock.

### Checkpoint 4: Scripts, setup e plugin prontos

- **Verificar:** nenhum script do repo referencia mais `opencode web` ou `opencode db`.
- **Validação:** `grep -rnE "opencode (web|db)" bin/ scripts/ run-*.sh` → nenhum resultado (exceto documentação histórica, que deve ser atualizada na T14).

### T14 — Atualizar a documentação principal

- [ ] **Status:** pendente
- **Depende de:** T8, T9, T10, T11, T12
- **Arquivos:** `AGENTS.md`, `README.md`
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given o `AGENTS.md` documenta `npm install -g opencode-linux-arm64 --force` e a seção "Scripts de Execução" descreve `opencode web`, When a T14 é executada, Then as instruções passam a documentar a instalação do `@opencode/cli@2.0.32` e o uso de `opencode serve`.
- Given o V2 exige senha, When a T14 é executada, Then o `AGENTS.md` e o `README.md` documentam `OPENCODE_PASSWORD`, a necessidade de entregar a senha/link `pair` ao usuário e o novo behaviour do serviço compartilhado.
- Given as convenções do repo, When a T14 é executada, Then as convenções ainda válidas (`--shared-tmp`, `exec`, `fire-and-forget` #21505, `0.0.0.0` crasha no proot, `stty sane`, `.env` via `$SCRIPT_DIR`) permanecem intactas.

**Verification:**

- **Run:** `grep -nE "opencode-linux-arm64|opencode web" AGENTS.md README.md | grep -v 'pkill -f "opencode web"'; grep -nE "opencode serve|OPENCODE_PASSWORD|@opencode/cli@2\.0\.32" AGENTS.md README.md`
- **Expected:** nenhuma ocorrência do binário/uso V1 antigo fora das menções históricas `pkill -f "opencode web"` (que permanecem por serem convenções de segurança válidas); o novo método de instalação e `serve`/senha documentados em ambos.

### T15 — Atualizar a documentação de orquestração

- [ ] **Status:** pendente
- **Depende de:** T7, T14
- **Arquivos:** `docs/MULTI_AGENT_ORCHESTRATION.md`, `AI_HANDOVER.md`
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given `docs/MULTI_AGENT_ORCHESTRATION.md` referencia `opencode debug agent` e a versão 1.19.3, When a T15 é executada, Then passa a referenciar `opencode debug agents` e a versão 2.0.32, com as permissões described no schema V2.
- Given `AI_HANDOVER.md` é um snapshot histórico, When a T15 é executada, Then ele é atualizado com um bloco "Migração V2" datado e um link para o ADR, preservando o histórico anterior.

**Verification:**

- **Run:** `grep -nE "debug agent\b|1\.19\.3" docs/MULTI_AGENT_ORCHESTRATION.md AI_HANDOVER.md; grep -nE "debug agents|2\.0\.32" docs/MULTI_AGENT_ORCHESTRATION.md AI_HANDOVER.md`
- **Expected:** o comando no singular e a versão 1.19.3 só aparecem em contexto explicitamente histórico; `debug agents` e `2.0.32` presentes.

### T16 — Registrar o ADR da migração

- [ ] **Status:** pendente
- **Depende de:** T14, T15
- **Arquivos:** `docs/decisions/ADR-010-migracao-opencode-v2-ga.md` (novo), `docs/decisions/README.md` (índice, se existir)
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given o formato dos ADR-008 e ADR-009 existentes, When a T16 é executada, Then o ADR-010 segue o mesmo template (Contexto / Decisão / Consequências / Alternativas consideradas / Referências).
- Given as decisões tomadas, When a T16 é executada, Then o ADR registra: target `2.0.32` fixado (e por que não `latest`=2.2.6), `web`→`serve`, Basic auth `opencode:<senha>` + `OPENCODE_PASSWORD`, isolamento do DB via `OPENCODE_DB`, `debug agent`→`debug agents`, `opencode db` removido, serviço compartilhado, e a decisão sobre o plugin.
- Given o V1 1.19.3 **também** honra `OPENCODE_DB` (verificado: `OPENCODE_DB=/data/data/com.termux/files/usr/tmp/v2poc/test.db opencode debug config` → exit 1, `Database is not empty and has no session table`, sem tocar o DB real do V1), When a T16 é executada, Then o ADR registra que `OPENCODE_DB` deve ser **sempre** scoped ao processo do V2 (prefixo por invocação), nunca exportado no shell/`.env`.
- Given a forma nativa equivalente extraída do output efetivo do V2 (T6), When a T16 é executada, Then o ADR registra o **follow-up** de conversão nativa V2 — `mcp` → `mcp.servers`, `model` → `{providerID, model}`, `skills.paths` → `skills`, `permission.skill` → `permissions: [{action, resource, effect}]` — **sem** converter os arquivos agora (shape V1 dual-compatible mantido).

**Verification:**

- **Run:** `ls docs/decisions/ && head -20 docs/decisions/ADR-010-migracao-opencode-v2-ga.md`
- **Expected:** o arquivo existe com as seções do template e o índice de ADRs referencia o ADR-010.

### Checkpoint 5: Documentação e ADR alinhados com o código

- **Verificar:** a documentação descreve o comportamento real já implementado nos scripts.
- **Validação:** `grep -rnE "opencode (web|db)" AGENTS.md README.md docs/ AI_HANDOVER.md` → apenas menções históricas marcadas como tal.

### T17 — Cutover: promover o V2 e migrar o DB com backup verificado

- [ ] **Status:** pendente
- **Depende de:** T3, T4, T6, T7, T10, T13, T14
- **Arquivos:** `/data/data/com.termux/files/usr/lib/node_modules/` (npm global do Termux), `/usr/bin/opencode`, `/usr/local/bin/opencode2`
- **Complexidade:** alta

**Acceptance (Given/When/Then):**

- Given o backup da T1 verificado por SHA-256 e o TUI ativo identificado, When a T17 é executada, Then o `opencode web` do V1 é parado **antes** de qualquer escrita no DB, e o binário V1 (`opencode-linux-arm64`) é preservado para rollback.
- Given o V2 é promovido, When `opencode --version` é executado, Then retorna `2.0.32` e `opencode2 --version` também, com `opencode` e `opencode2` apontando para o mesmo binário V2.
- Given o DB do V1 tem ~3,1 GB, When o V2 é iniciado **sem** `OPENCODE_DB` para forçar a migração nativa, Then o processo termina sem erro e `opencode2 debug paths` mostra o DB no caminho padrão; se a migração nativa falhar, Then o operator restaura o backup da T1 e usa `OPENCODE_DB` apontando para uma cópia isolada, sem perda de dados.
- Given `OPENCODE_DB` exportado no ambiente do Termux, When o V1 é reiniciado, Then o V1 **não** deve ser afetado — o `OPENCODE_DB` fica no prefixo do comando do V2.

**Verification:**

- **Run:** `opencode --version; opencode2 --version; opencode2 debug paths | grep -i db; ls -lh ~/.local/share/opencode/`
- **Expected:** `2.0.32` nos dois binários; o DB no caminho padrão com tamanho coerente; o backup da T1 ainda intacto e com checksum igual ao registrado.

### T18 — Testes E2E no device

- [ ] **Status:** pendente
- **Depende de:** T17
- **Arquivos:** nenhum (teste); evidência em `docs/SESSION_CONTEXT_<data>.md` (T20)
- **Complexidade:** alta

**Acceptance (Given/When/Then):**

- Given o cutover feito, When `opencode_web` é executado, Then o tunnel Cloudflare sobe, a URL é entregue via ntfy **junto com a senha/link `pair`**, e a UI V2 é acessível pelo túnel — o health-check usa a rota **conhecida** `/api/agent` autenticada **e** valida `content-type: application/json` (status HTTP sozinho não basta: rota inexistente sob `/api/*` devolve 404 e qualquer path fora de `/api/*` devolve 200 text/html do SPA).
- Given o cutover feito, When `opencode_tailscale` é executado, Then o serviço Tailscale sobe e a UI V2 responde autenticada.
- Given o `serve` do V2 no proot, When `opencode2 api --server http://127.0.0.1:4096 GET /api/agent` é executado com `OPENCODE_PASSWORD`, Then retorna JSON 200 sem `UnauthorizedError`.
- Given os scripts de stop, When `opencode_web_stop` e `opencode_tailscale_stop` são executados, Then nenhum processo `opencode` sobra (verificado por `ps`) e o TUI **não** foi morto.

**Verification:**

- **Run:** `opencode_web && sleep 20 && curl -s -o /dev/null -w '%{http_code} %{content_type}\n' -u "opencode:$OPENCODE_PASSWORD" https://<host-tunnel>/api/agent; opencode_web_stop; ps -eo pid,args | grep -cE "[s]erve --service|[o]pencode2 serve"`
- **Expected:** `200 application/json` no tunnel; após o stop, `0` processos V2 residuais — o padrão `[s]erve --service|[o]pencode2 serve` é obrigatório porque o serviço compartilhado roda como `/.l2s/.l2s.opencode0001.0002 serve --service` (proot `--link2symlink`) e **não** casa com `opencode serve` nem com `opencode2` — e o TUI ainda ativo.

### T19 — Rollback testado

- [ ] **Status:** pendente
- **Depende de:** T17, T18
- **Arquivos:** `docs/rollback-opencode-v2.md` (novo)
- **Complexidade:** média

**Acceptance (Given/When/Then):**

- Given o cutover feito, When o procedimento de rollback é executado num ambiente de teste (restore do DB + reativação do V1), Then o V1 volta a servir a UI em `http://127.0.0.1:4096` e `opencode --version` volta a `1.19.3`.
- Given o rollback, When o DB é restaurado, Then o checksum SHA-256 do DB restaurado é **igual** ao registrado na T1 (nenhum dado perdido no processo).

**Verification:**

- **Run:** `diff <(sha256sum ~/.local/share/opencode/opencode.db | cut -d' ' -f1) <(cut -d' ' -f1 /data/data/com.termux/files/usr/tmp/opencode-v1-backup-*/opencode.db.sha256)`
- **Expected:** os dois hashes coincidem (sem diferença na saída do `diff`).

### T20 — Fechamento documental e índice de planos

- [ ] **Status:** pendente
- **Depende de:** T16, T19
- **Arquivos:** `.opencode/plans/README.md`, `docs/SESSION_CONTEXT_<data>.md` (novo)
- **Complexidade:** baixa

**Acceptance (Given/When/Then):**

- Given o plano concluído, When a T20 é executada, Then `.opencode/plans/README.md` lista o plano em "Ativos" (ou "Arquivados", se já movido para `archive/`) com o commit de referência.
- Given a migração concluída, When a T20 é executada, Then o novo `docs/SESSION_CONTEXT_<data>.md` documenta o estado final (versões instaladas, caminhos de config, formato do DB, auth por senha, comandos operacionais e lições aprendidas).

**Verification:**

- **Run:** `grep -n "20261022_1023_migracao-opencode-2.0" .opencode/plans/README.md; ls docs/SESSION_CONTEXT_*.md`
- **Expected:** o plano aparece no índice e o novo SESSION_CONTEXT existe com o padrão de nome do repositório.

### Checkpoint Final: Migração concluída e reversível

- **Verificar:** todas as tasks acima concluídas, cutover validado E2E, rollback testado.
- **Validação:** `opencode --version` → `2.0.32`; `opencode2 debug agents` → 5 agentes do repo + `build`/`plan`; E2E do tunnel respondendo JSON autenticado; `opencode_web_stop` sem órfãos; checksum do DB de rollback idêntico ao da T1.

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| V2 GA alterar/migrar o DB `opencode.db` do V1 em place (mesmo caminho nos 3 canais), quebrando o fallback | **Alta** | **Alto** | Isolar com `OPENCODE_DB` em todo o PoC (T4); backup SHA-256 verificado antes de qualquer escrita (T1); validar o mecanismo de migração `opencode-next.db` antes do cutover (T17) |
| Senha do servidor ausente ou não entregue ao usuário → tunnel abre mas a UI retorna 401 | **Alta** | **Alto** | Senha gerada/persistente em `$PREFIX/tmp/opencode_password.txt` (chmod 600, **fora do repo** — o `.env` versionado não a recebe); entregue na notificação ntfy ou via `opencode2 pair --url` (T8/T9); health-check por `content-type`, não por HTTP 200 |
| Colisão do bin `opencode` entre `opencode-linux-arm64@1.19.3` e `@opencode/cli@2.0.32` na instalação global do Termux | **Alta** | **Médio** | Instalação side-by-side em prefixo isolado (T3); cutover remove o V1 **depois** do V2 validado (T17); bin V1 preservado para rollback (T19) |
| `@opencode/cli@latest` migrar para 2.2.6 (ou superior) sem aviso e introduzir breaking changes não testados | **Média** | **Médio** | Fixar `@opencode/cli@2.0.32` em todos os manifests e no setup.sh; nunca instalar sem versão explícita (T3/T12) |
| Autostart do serviço compartilhado (`serve --service`) deixar processos órfãos e portões ocupados, confuso com o TUI | **Média** | **Médio** | Stop scripts param o processo `serve` **e** o `opencode service` (T10); verificação por `ps` no E2E (T18); nunca `pkill -f "opencode web"` |
| `run-cloudflare-tunnel.sh` morrer junto com o TUI (é filho do processo do TUI) durante o cutover | **Média** | **Médio** | Identificar e reiniciar o TUI explicitamente antes do cutover; o wrapper `bin/opencode-web.sh` (fire-and-forget, com `disown`) é o ponto de entrada suportado (T17/T18) |
| Migração nativa de ~3,1 GB de sessões exceder o espaço em disco ou demorar excessivamente | **Média** | **Alto** | Confirmar espaço livre ≥ 4 GB antes do cutover; testar a migração numa **cópia** do DB real antes de aplicar no lugar; fallback: `OPENCODE_DB` apontando para cópia isolada |
| Dependência de plugin `@opencode-ai/plugin` órfã quebrar o `npm install` do setup com a versão do V2 | **Média** | **Baixo** | Decidir e registrar no ADR antes do cutover (T13); `npm install` do setup já é `|| true` |
| Loss de funcionalidade: algum comando V1 removido ainda referenciado por scripts ou docs | **Média** | **Médio** | Varredura `grep -rnE "opencode (web|db)"` no repo (Checkpoint 4/5); `debug agent`→`debug agents` verificado em T7/T15 |
| Regressão no behaviour do tunnel por mudança no parsing da URL do Cloudflare / saída do V2 | **Baixa** | **Médio** | Manter o parsing atual da URL e validar o formato exato do output do V2 antes de alterar o regex (T8); E2E no device (T18) |

## Verificação Final

1. `opencode --version` → `2.0.32`; `opencode2 --version` → `2.0.32` (mesmo binário).
2. `opencode2 debug agents` → inclui `task-build`, `task-planner`, `dev`, `code-review`, `git-commit`.
3. `opencode2 debug config` → lista a config global do repo e a do projeto, sem warnings de schema.
4. `grep -rnE "opencode (web|db)" bin/ scripts/ run-*.sh` → **nenhuma** ocorrência.
5. `curl -u opencode:$OPENCODE_PASSWORD https://<tunnel>/api/agent` → `200` + `application/json`; sem `-u` → `401`.
6. `opencode_web_stop` → `ps -eo pid,args | grep -cE "[s]erve --service|[o]pencode2 serve"` → `0` e TUI intacto.
7. Checksum SHA-256 do DB de rollback idêntico ao da T1.
8. `git status` limpo no commit final; plano arquivado e índice `.opencode/plans/README.md` atualizado.

## Feature List

```json
{
  "features": [
    { "id": 1, "name": "T1 — Backup integral do ambiente V1", "status": "done", "acceptance": ["Given o V1 rodando com ~3,1 GB de opencode.db, When a T1 é executada, Then existe cópia verbatim de DB, WAL, auth.json e account.json com checksum SHA-256", "Given ~/.config/opencode é symlink, When a T1 é executada, Then o tarball do conteúdo resolvido existe sem seguir o link"] },
    { "id": 2, "name": "T2 — Notas de breaking changes V1→V2", "status": "done", "acceptance": ["Given o levantamento empirico, When a T2 é executada, Then docs/opencode-v2-migration-notes.md documenta CLI, auth, DB, serviço compartilhado e o desvio latest=2.2.6 (2.1.3 em 22/10/2026)", "Given a nota, When se busca 'senha do servidor', Then a resposta cita o código-fonte do binário que a comprova"] },
    { "id": 3, "name": "T3 — Instalar V2 2.0.32 isolado", "status": "done", "acceptance": ["Given o V1 instalado, When a T3 é executada, Then opencode --version continua 1.19.3 e opencode2 --version retorna 2.0.32", "Given o prefixo isolado, When se lista, Then @opencode/cli está em 2.0.32 e não 2.2.6"] },
    { "id": 4, "name": "T4 — PoC funcional do V2 isolado", "status": "done", "acceptance": ["Given OPENCODE_DB isolado, When o serve sobe, Then o processo V2 não tem NENHUM fd para ~/.local/share/opencode/opencode.db (verificado via /proc/<pid>/fd) e tem fds apenas para $OPENCODE_DB{,-wal,-shm}", "Given OPENCODE_PASSWORD, When curl -u opencode:<senha> /api/agent, Then 200 JSON; sem -u, Then 401 UnauthorizedError"] },
    { "id": 5, "name": "T5 — Config global V2 (shape V1 mantido)", "status": "done", "acceptance": ["Given a config global em shape V1, When a T5 é executada, Then mantém o shape V1 (mcp como objeto, RENDER_API_KEY como {env:RENDER_API_KEY}) sem paths absolutos de skills", "Given a config global dual-compatible, When opencode2 debug config roda, Then lista a global e a do projeto, o MCP render aparece configurado e não há aviso de schema desconhecido"] },
    { "id": 6, "name": "T6 — Config do projeto V2 (shape V1 mantido)", "status": "done", "acceptance": ["Given permission.skill do V1, When a T6 é executada, Then o shape V1 é mantido e o V2 traduz permission.skill em 50 entradas permissions com effect allow, preservando model e skills.paths", "Given external_directory, When a T6 é executada, Then fica registrado que a regra NÃO existe no opencode.json deste repo e que a conversão nativa V2 é follow-up da T16"] },
    { "id": 7, "name": "T7 — Validar agentes e skills no V2", "status": "done", "acceptance": ["Given 5 agentes e 50 skills, When opencode2 debug agents roda, Then os 5 agentes de orquestração aparecem com permission preenchido e nenhum skill quebra"] },
    { "id": 8, "name": "T8 — Migrar run-*.sh para serve + senha", "status": "pending", "acceptance": ["Given os launchers com opencode web, When a T8 é executada, Then ambos usam opencode serve preservando exec e --shared-tmp", "Given o V2 exigir senha, When o launcher sobe, Then OPENCODE_PASSWORD é definido antes do serve e a senha é persistida em arquivo de handoff"] },
    { "id": 9, "name": "T9 — Migrar wrappers Termux", "status": "pending", "acceptance": ["Given o V2 exigir senha, When a notificação ntfy é montada, Then inclui URL e senha ou link one-time do pair"] },
    { "id": 10, "name": "T10 — Migrar stop scripts", "status": "pending", "acceptance": ["Given o serviço compartilhado do V2, When o stop script roda, Then encerra serve e opencode service sem pkill -f 'opencode web'", "Given o ADR-009, When a T10 é executada, Then graceful→kill -9→is_zombie→stty sane são preservados"] },
    { "id": 11, "name": "T11 — Migrar limpar-opencode.sh", "status": "pending", "acceptance": ["Given opencode db removido, When a T11 é executada, Then o script limpa o DB por remoção de arquivo preservando auth.json e account.json"] },
    { "id": 12, "name": "T12 — Migrar setup.sh", "status": "pending", "acceptance": ["Given o setup, When a T12 é executada, Then instala @opencode/cli@2.0.32 fixado e mantém symlink e npm install"] },
    { "id": 13, "name": "T13 — Dependência de plugin órfã", "status": "pending", "acceptance": ["Given nenhuma fonte de plugin, When a T13 é executada, Then a decisão está no ADR e os dois package.json ficam coerentes"] },
    { "id": 14, "name": "T14 — Docs principais", "status": "pending", "acceptance": ["Given o AGENTS.md, When a T14 é executada, Then documenta @opencode/cli@2.0.32, opencode serve, OPENCODE_PASSWORD e o serviço compartilhado, preservando as convenções"] },
    { "id": 15, "name": "T15 — Docs de orquestração", "status": "pending", "acceptance": ["Given MULTI_AGENT_ORCHESTRATION.md cita debug agent e 1.19.3, When a T15 é executada, Then cita debug agents e 2.0.32", "Given AI_HANDOVER.md, When a T15 é executada, Then ganha um bloco datado 'Migração V2' com link para o ADR"] },
    { "id": 16, "name": "T16 — ADR da migração", "status": "pending", "acceptance": ["Given ADR-008/009, When a T16 é executada, Then ADR-010 segue o mesmo template e registra as 8 decisões-chave"] },
    { "id": 17, "name": "T17 — Cutover V1→V2", "status": "pending", "acceptance": ["Given o backup verificado, When a T17 é executada, Then o V1 é parado antes de escrever no DB e o binário V1 é preservado", "Given o cutover, When opencode --version roda, Then retorna 2.0.32 e opencode2 também, sem perda de dados"] },
    { "id": 18, "name": "T18 — E2E no device", "status": "pending", "acceptance": ["Given o cutover, When opencode_web sobe, Then o tunnel entrega URL+senha e /api responde JSON autenticado", "Given os stops, When opencode_web_stop roda, Then não sobra processo e o TUI não é morto"] },
    { "id": 19, "name": "T19 — Rollback testado", "status": "pending", "acceptance": ["Given o rollback executado, Then o V1 volta a servir na 4096 e o SHA-256 do DB restaurado é igual ao da T1"] },
    { "id": 20, "name": "T20 — Fechamento documental", "status": "pending", "acceptance": ["Given o plano concluído, When a T20 é executada, Then o índice .opencode/plans/README.md é atualizado e um novo SESSION_CONTEXT é criado"] }
  ]
}
```
