# Notas de migração OpenCode V1 → V2 (breaking changes)

- **Data:** 08/11/2026
- **Versões:** V1 `1.19.3` → V2 `2.0.32` (V2 GA; versão **fixada**, não usar `@latest`)
- **Plano de origem:** `.opencode/plans/20261022_1023_migracao-opencode-2.0.md` (task T2)

> **Aviso:** os dados empíricos foram coletados no device (Termux + proot Ubuntu, arm64) e podem variar em outro ambiente. Valores como tamanho do DB/WAL, PID do serviço e a versão publicada em `@latest` mudam com o tempo — reexecute o comando antes de tomar decisão.

## Convenção de proveniência

- **“verificado em 22/10/2026 pelo levantamento do plano”** — evidência coletada na investigação que gerou o plano (binário extraído em `/tmp/opencode/v2inspect/` e PoC da T4), não reexecutada agora.
- **“revalidado em 08/11/2026”** — comando reexecutado neste device na data desta nota.
- **`opencode2`** — nome do binário V2 após a instalação side-by-side (T3). Antes da T3, use o caminho do binário extraído: `/tmp/opencode/v2inspect/package/bin/opencode`.

### Como reproduzir os comandos V2 antes da T3

```bash
# antes da T3 (opencode2 ainda não instalado):
V2=/tmp/opencode/v2inspect/package/bin/opencode
"$V2" --help
# depois da T3:
V2=opencode2
```

> Nos blocos **“Como comprovar”** das seções 1–10, substitua `opencode2` por `"$V2"` enquanto a T3 não tiver sido executada.

## Resumo

| # | Breaking change | Impacto |
| --- | --- | --- |
| 1 | `opencode web` e `opencode db` removidos → `opencode serve` | Scripts `run-*.sh` e `limpar-opencode.sh` |
| 2 | `debug agent` → `debug agents` | Documentação e troubleshooting |
| 3 | API em `/api/*`; rota inexistente sob `/api/*` → 404; fora de `/api/*` → SPA (HTML 200) | Health-check: rota conhecida `/api/agent` + `content-type` |
| 4 | Basic auth com usuário fixo `opencode`; `Bearer` não funciona | Clientes, curl e tunnel |
| 5 | `OPENCODE_PASSWORD` (V2) vs. `OPENCODE_SERVER_PASSWORD` (V1) | Launchers e notificação |
| 6 | V1, beta e GA compartilham `opencode.db` | Risco de quebrar o fallback V1 |
| 7 | Serviço compartilhado `serve --service` autostarta | Stop scripts e portas |
| 8 | `@latest` ≠ `2.0.32`; dois bins (`opencode`, `opencode2`) | Instalação e colisão de bin |
| 9 | Pacotes `@opencode/cli` + `@opencode/cli-linux-arm64` | Instalação no Termux |
| 10 | DB de ~3,3 GB + WAL ~230 MB | Backup e espaço em disco |
| 11 | Instalação no Termux/proot: shim `os.platform` + `--force` + pin exato | `scripts/setup.sh` (T12) |
| 12 | `service.json` grava a senha do serviço em texto claro **dentro do repo** (via symlink) e `service stop` **não** o remove | `.gitignore` + limpeza manual obrigatória |
| 13 | O log do V2 é **compartilhado** com o V1 (`~/.local/share/opencode/log/opencode.log`, mesmo inode) — `OPENCODE_DB` isola o DB, **não** o log | Diagnóstico e leitura de log |
| 14 | O serviço compartilhado roda como `/.l2s/.l2s.opencode0001.0002 serve --service` (proot `--link2symlink`) — não casa com `opencode serve` nem `opencode2` | Detecção de processos residuais |
| 15 | A senha do servidor vive **fora do repo** (`$PREFIX/tmp/opencode_password.txt`, chmod 600) | `.env` versionado não a recebe |

---

## 1. `opencode web` e `opencode db` foram removidos; `opencode serve --hostname --port` é o substituto

**O que muda:** o V1 tinha `opencode web` (servidor + UI) e `opencode db` (ferramentas de banco). No V2 ambos saíram da lista de subcomandos; o servidor HTTP/API + web passa a ser `opencode serve --hostname <host> --port <port>`.

**Como comprovar:**

```bash
# V1 (1.19.3): os comandos existem
opencode web --help | head -3
opencode db --help | head -3

# V2 (2.0.32): não existem mais na lista de subcomandos
opencode2 --help | grep -E '^  (web|db)(,| )'
# esperado: nenhuma linha

opencode2 serve --help | head -3
```

**Resultado esperado:**

```text
# V1
opencode web
start opencode server and open web interface
...
opencode db
database tools
...

# V2 — nenhuma linha para web/db; e o serve existe:
Start the v2 API and web server
```

**Atenção:** no V2, um subcomando desconhecido **não retorna erro** — ele imprime a ajuda do comando pai com exit code `0`. Portanto, comprove a remoção pela lista `SUBCOMMANDS`, nunca pelo status de saída.

**Proveniência:** V1 revalidado em 08/11/2026; V2 revalidado em 08/11/2026 com o binário em `/tmp/opencode/v2inspect/package/bin/opencode`; remoção também verificada em 22/10/2026 pelo levantamento do plano.

---

## 2. `debug agent` virou `debug agents` (plural)

**O que muda:** o subcomando de depuração que lista agentes passou de `debug agent` (singular, V1) para `debug agents` (plural, V2).

**Como comprovar:**

```bash
# V2: o subcomando listado é "agents"
opencode2 debug --help | grep -E '^  agents'
# esperado: agents    List all agents

opencode2 debug agents | head
# esperado: lista/JSON dos agentes carregados
```

**Resultado esperado:**

```text
  agents    List all agents
  config    List configuration sources
  paths     Show global paths (data, config, cache, state)
```

**Atenção:** `opencode2 debug agent` (singular) cai no fallback de ajuda do `debug` (exit `0`), não em um erro explícito. Confirme o plural pela lista de subcomandos.

**Proveniência:** revalidado em 08/11/2026 (saída de `debug --help`).

---

## 3. API base em `/api/*`; rota inexistente sob `/api/*` → 404; fora de `/api/*` → SPA (HTML 200)

**O que muda:** a API JSON vive sob `/api/*` (além de `/auth/*` e `/openapi.json`). O roteamento é **duplo**:

- **Sob `/api/*`**: rota **inexistente** → **HTTP 404** (corpo vazio ou JSON de erro) — **nunca** cai no SPA.
- **Fora de `/api/*`**: qualquer path → **HTTP 200 `text/html`** (fallback do SPA, `index.html`).

Logo, “status 200” não prova que a API está saudável (fora de `/api/*` qualquer path devolve 200 do SPA). O health-check correto usa uma rota **conhecida** (`/api/agent`) **e** valida `content-type: application/json` — status HTTP sozinho não basta.

**Tabela real medida (08/11/2026, V2 2.0.32, `serve` em `127.0.0.1:4098`, DB isolado):**

| Rota | Credencial | HTTP | `content-type` | Corpo |
| --- | --- | --- | --- | --- |
| `/api/agent` | sim | `200` | `application/json` | 1ª requisição (cold start): `{"location":{"directory":"…"},"data":[]}`; após warm-up: `data` com 12 agentes |
| `/api/agent` | não | `401` | `application/json` | `{"_tag":"UnauthorizedError","message":"Authentication required"}` |
| `/api/rota-que-nao-existe` | sim | `404` | *(vazio)* | 0 bytes |
| `/api/rota-que-nao-existe` | não | `401` | `application/json` | `UnauthorizedError` |
| `/api` (raiz) | sim | `404` | *(vazio)* | 0 bytes |
| `/rota-que-nao-existe` (fora de `/api/*`) | não | `200` | `text/html` | `index.html` do SPA (≈ 7 KB) |

> **Cold start:** o `data:[]` da 1ª requisição a `/api/agent` **não** é o estado estável — é o cold start do processo. Após o warm-up, a mesma rota devolve `data` com 12 agentes. Qualquer verificação que conte agentes precisa de **retry** até o warm-up.

**Como comprovar:**

```bash
# Servidor V2 de teste (ver T4 do plano)
mkdir -p /data/data/com.termux/files/usr/tmp/v2poc
OPENCODE_DB="/data/data/com.termux/files/usr/tmp/v2poc/test.db" \
OPENCODE_PASSWORD=senha-de-teste-123 \
opencode2 serve --hostname 127.0.0.1 --port 4097 &

# Rota de API real (autenticada)
curl -s -o /dev/null -w '%{http_code} %{content_type}\n' \
  -u 'opencode:senha-de-teste-123' \
  http://127.0.0.1:4097/api/agent

# Rota inexistente SOB /api/* → 404 (nunca o SPA)
curl -s -o /dev/null -w '%{http_code} %{content_type}\n' \
  -u 'opencode:senha-de-teste-123' \
  http://127.0.0.1:4097/api/rota-que-nao-existe

# Rota inexistente FORA de /api/* → 200 text/html (fallback do SPA)
curl -s -o /dev/null -w '%{http_code} %{content_type}\n' \
  http://127.0.0.1:4097/rota-que-nao-existe
```

**Resultado esperado:**

```text
200 application/json     # /api/agent autenticado
404                      # /api/rota-que-nao-existe → 404, corpo vazio
200 text/html            # /rota-que-nao-existe → fallback do SPA
```

**Trecho extraído do binário (comprova o roteamento):**

```bash
strings "$(command -v opencode2)" \
  | grep -o 'pathname==="/api".\{0,200\}' | head -1
```

```text
pathname==="/api"||i.pathname.startsWith("/api/")||i.pathname.startsWith("/auth/")||i.pathname==="/openapi.json")return yield*n.pipe(wo(Se,()=>l(Pr({status:404}))));return yield*d.pipe(h((a)=>Oe(s,i,a.files,a.brotli))
```

**Proveniência:** comportamento e valores de `curl` verificados em 22/10/2026 pelo levantamento do plano (PoC da T4); trecho de código revalidado em 08/11/2026. A **tabela real medida** acima (incluindo o `404` sob `/api/*`) foi revalidada em 08/11/2026 com `serve` em `127.0.0.1:4098` e DB isolado em `/data/data/com.termux/files/usr/tmp/v2poc/routes.db`.

---

## 4. Basic auth com usuário fixo `opencode` + senha do servidor; `Bearer` NÃO é suportado

**O que muda:** a autenticação é **HTTP Basic**, com usuário **fixo `opencode`** e a senha do servidor. Sem credencial, a resposta é `401` com `UnauthorizedError`; `Authorization: Bearer <senha>` também retorna `401`.

**Como comprovar:**

```bash
# Com credencial correta
curl -s -o /dev/null -w '%{http_code}\n' \
  -u 'opencode:senha-de-teste-123' \
  http://127.0.0.1:4097/api/agent
# esperado: 200

# Sem credencial
curl -s -o /dev/null -w '%{http_code}\n' \
  http://127.0.0.1:4097/api/agent
# esperado: 401

# Bearer não é aceito
curl -s -o /dev/null -w '%{http_code}\n' \
  -H 'Authorization: Bearer senha-de-teste-123' \
  http://127.0.0.1:4097/api/agent
# esperado: 401

# Corpo do 401 sem credencial
curl -s http://127.0.0.1:4097/api/agent
# esperado: {"_tag":"UnauthorizedError","message":"Authentication required"}
```

**Trecho extraído do binário (comprova o usuário fixo):**

```bash
strings "$(command -v opencode2)" \
  | grep -o 'authorization:"Basic "[^,]*' | head -1
strings "$(command -v opencode2)" \
  | grep -o 'type:"basic",username:"opencode"[^}]*}' | head -1
```

```text
authorization:"Basic "+Buffer.from(`opencode:${i.password}`).toString("base64")}})
type:"basic",username:"opencode",password:e.password}
```

**Proveniência:** respostas `200`/`401` e rejeição de `Bearer` verificadas em 22/10/2026 pelo levantamento do plano; trechos de código revalidados em 08/11/2026.

---

## 5. `OPENCODE_PASSWORD` (V2) — se ausente, senha aleatória por start; no V1 a variável é outra (`OPENCODE_SERVER_PASSWORD`)

**O que muda:** no V2, a senha do servidor vem de `OPENCODE_PASSWORD`. Se a variável **não** estiver definida, o `serve` gera uma senha aleatória de 32 bytes **a cada start** e a imprime no stdout (`server password <senha>`). No V1, o `opencode web` usa **`OPENCODE_SERVER_PASSWORD`** e avisa que o servidor está inseguro quando ela falta — **não confundir as duas variáveis**.

**Como comprovar (V2):**

```bash
# Sem OPENCODE_PASSWORD: senha aleatória impressa no start
mkdir -p /data/data/com.termux/files/usr/tmp/v2poc
OPENCODE_DB="/data/data/com.termux/files/usr/tmp/v2poc/test.db" \
opencode2 serve --hostname 127.0.0.1 --port 4097
# stdout esperado:
#   server listening on http://127.0.0.1:4097
#   server password <senha aleatória>

# Com OPENCODE_PASSWORD: a senha é estável e não é impressa
OPENCODE_DB="/data/data/com.termux/files/usr/tmp/v2poc/test.db" \
OPENCODE_PASSWORD=senha-de-teste-123 \
opencode2 serve --hostname 127.0.0.1 --port 4097
# esperado: só "server listening on ...", sem a linha "server password ..."
```

**Como comprovar (V1):**

```bash
timeout 5 opencode web --hostname 127.0.0.1 --port 4096 2>&1 | grep 'OPENCODE_SERVER_PASSWORD'
# stderr esperado (quando a variável falta):
#   OPENCODE_SERVER_PASSWORD is not set; server is unsecured

# A variável do V1 é OPENCODE_SERVER_PASSWORD, não OPENCODE_PASSWORD
strings "$(command -v opencode)" \
  | grep -c 'OPENCODE_SERVER_PASSWORD is not set; server is unsecured'
# esperado: 2
strings "$(command -v opencode)" | grep -c 'OPENCODE_PASSWORD'
# esperado: 0
```

**Trecho extraído do binário V2 (senha aleatória + impressão condicional):**

```bash
strings "$(command -v opencode2)" \
  | grep -o 'e.mode==="service"?a.password||z(32).\{0,120\}' | head -1
strings "$(command -v opencode2)" \
  | grep -o 'server listening on \${F}`),s&&!O)console.log(`server password \${w}`)' | head -1
```

```text
e.mode==="service"?a.password||z(32).toString("base64url"):O?Fs(O):z(32).toString("base64url")
server listening on ${F}`),s&&!O)console.log(`server password ${w}`)
```

**Nota adicional (V2):** o código do V2 lê `OPENCODE_PASSWORD` e, como fallback, aceita `OPENCODE_SERVER_PASSWORD` (`U7("OPENCODE_PASSWORD").pipe(Jq(()=>U7("OPENCODE_SERVER_PASSWORD")))`). A variável canônica documentada continua sendo `OPENCODE_PASSWORD`.

**Proveniência:** saída do `serve` verificada em 22/10/2026 pelo levantamento do plano; presença/ausência das strings nos binários V1 e V2 revalidada em 08/11/2026.

---

## 6. Colisão de DB: V1, beta e GA gravam no mesmo `opencode.db`; isolar com `OPENCODE_DB`

**O que muda:** o caminho padrão do banco é `~/.local/share/opencode/opencode.db` para o V1 **e** para o V2 GA/beta (canais `latest`, `dev`, `beta`, `next`, `prod`). Não há isolamento por canal por padrão. Rodar o V2 sobre a instalação real pode migrar/alterar o DB do V1 e quebrar o fallback. Isole com `OPENCODE_DB` até o cutover.

**Como comprovar (caminho padrão):**

```bash
opencode2 debug paths | grep -E '^\s*db\s'
# esperado: db  /root/.local/share/opencode/opencode.db
```

**Como comprovar (regra de escolha do arquivo):**

```bash
strings "$(command -v opencode2)" \
  | grep -o 'OPENCODE_DB??(\[.\{0,260\}' | head -1
```

```text
OPENCODE_DB??(["latest","dev","beta","next","prod"].includes(Ul)||process.env.OPENCODE_DISABLE_CHANNEL_DB==="1"||process.env.OPENCODE_DISABLE_CHANNEL_DB==="true"?"opencode.db":`opencode-${Ul.replace(/[^a-zA-Z0-9._-]/g,"-")}.db`);return e===":memory:"?e:r.resolve(o,e)}
```

**Como comprovar (isolamento por fd — critério mais forte que mtime/tamanho):**

```bash
mkdir -p /data/data/com.termux/files/usr/tmp/v2poc
OPENCODE_DB="/data/data/com.termux/files/usr/tmp/v2poc/test.db" \
OPENCODE_PASSWORD=senha-de-teste-123 \
opencode2 serve --hostname 127.0.0.1 --port 4097 &
PID=$!
sleep 12

# fds de DB do processo V2: apenas $OPENCODE_DB{,-wal,-shm}
ls -l /proc/$PID/fd | grep -E 'opencode.*\.db'
# esperado: NENHUM fd para ~/.local/share/opencode/opencode.db

# Cleanup obrigatório
kill "$PID"; wait "$PID"; opencode2 service stop
```

> O critério por fd é mais forte que comparar mtime/tamanho: o processo do V2 **não tem handle nenhum** sobre o DB do V1. `OPENCODE_DB` isola o **DB**, mas **não** o log (ver seção 12.2).

**Como comprovar (migração V1→V2):**

```bash
strings "$(command -v opencode2)" \
  | grep -E 'opencode-next\.db|Migrating sessions|session_message' | head
```

**Resultado esperado:** as três strings aparecem. A migração lê um DB “next” (`opencode-next.db` por padrão, sobrescrevível por `nextDatabasePath`) e copia sessões V1 (`session`, `message`, `part`) para as tabelas V2 (`session_message`), em fases rotuladas `Migrating sessions`.

**Proveniência:** fato de GA e beta criarem o mesmo `opencode.db` verificado em 22/10/2026 pelo levantamento do plano; caminho padrão (`debug paths`) e trechos de código revalidados em 08/11/2026.

---

## 7. Autostart do serviço compartilhado (`serve --service`) e `opencode service start|restart|status`

**O que muda:** o V2 usa um **servidor de background compartilhado**. Rodar um cliente (ex.: `debug config`) já autostarta `opencode2 serve --service`; clientes (`run`, `api`, TUI) conectam-se a esse serviço. O ciclo de vida é gerenciado por `opencode service`.

**Como comprovar:**

```bash
# O modo serviço existe no serve
opencode2 serve --help | grep -E -- '--service|--stdio'
# esperado: --service e --stdio listados

# O comando service gerencia o servidor de background
opencode2 service --help | grep -E '^  (start|restart|status|stop)'
# esperado: start, restart, status, stop

# Observação do autostart (após rodar qualquer cliente V2)
ps -eo pid,args | grep -E '[s]erve --service|[o]pencode2 serve'
# esperado: /.l2s/.l2s.opencode0001.0002 serve --service  (ver seção 12.3)
```

**Resultado esperado:**

```text
  start      Start the background server
  restart    Restart the background server
  status     Show background server status
  stop       Stop the background server
```

**Atenção:** `--service` e `--stdio` não podem ser combinados (o binário contém `--service and --stdio cannot be combined`). O `serve` standalone (fora do serviço compartilhado) não atende os clientes que esperam o serviço.

**Proveniência:** autostart observado (PID) em 22/10/2026 pelo levantamento do plano; lista de subcomandos de `service` e `serve` revalidada em 08/11/2026.

---

## 8. `@opencode/cli@latest` = 2.2.6 (não 2.0.32) → fixar `2.0.32`; o bin publica `opencode` e `opencode2`

**O que muda:** o `@latest` **não** para no GA alvo. Em 22/10/2026 já apontava para **2.1.3**; em 08/11/2026 já estava em **2.2.6** — sempre mais novo que o GA alvo `2.0.32`. Instalar sem versão explícita traz breaking changes não testados. Além disso, o pacote publica **dois bins** (`opencode` e `opencode2`) apontando para o mesmo executável — o bin `opencode` colide com o binário V1 do npm global do Termux.

**Como comprovar:**

```bash
npm view @opencode/cli@latest version
# esperado em 22/10/2026: 2.1.3
# esperado em 08/11/2026: 2.2.6
# o número muda com o tempo — por isso fixar a versão exata

npm view @opencode/cli@2.0.32 version
# esperado: 2.0.32

npm view @opencode/cli@2.0.32 bin --json
# esperado:
# {
#   "opencode": "bin/opencode.exe",
#   "opencode2": "bin/opencode.exe"
# }
```

**Proveniência:** valores de 22/10/2026 pelo levantamento do plano. Revalidado em 08/11/2026: `@latest` já estava em **2.2.6** e `@2.0.32` continuava em `2.0.32` — o valor de `latest` deriva com o tempo, a regra de fixar a versão exata `2.0.32` permanece.

---

## 9. Pacotes: `@opencode/cli@2.0.32` + optional dep `@opencode/cli-linux-arm64@2.0.32`

**O que muda:** no arm64, a instalação usa o pacote principal `@opencode/cli@2.0.32`, que resolve a dependência opcional de plataforma `@opencode/cli-linux-arm64@2.0.32` (o binário real).

**Como comprovar:**

```bash
npm view @opencode/cli@2.0.32 version
npm view @opencode/cli@2.0.32 optionalDependencies --json \
  | grep 'cli-linux-arm64'
npm view @opencode/cli-linux-arm64@2.0.32 version dist.unpackedSize --json
```

**Resultado esperado:**

```text
2.0.32
"@opencode/cli-linux-arm64": "2.0.32",
{
  "version": "2.0.32",
  "dist.unpackedSize": 207473176
}
```

São duas métricas distintas: `dist.unpackedSize` do npm = **207.473.176 B** (tamanho descompactado reportado pelo pacote); binário em disco = **207.472.936 B** (~198 MiB), medido em 08/11/2026. Reserve espaço para ele no prefixo isolado.

**Proveniência:** versões verificadas em 22/10/2026 pelo levantamento do plano; `bin`, `optionalDependencies` e `unpackedSize` revalidados em 08/11/2026.

---

## 10. Tamanho dos dados locais — snapshot do backup da T1 (08/11/2026 00:17)

**O que muda:** o DB é grande o suficiente para exigir backup e espaço livre antes de qualquer migração. O valor `3268820992` abaixo é o tamanho do **snapshot do backup da T1** (cópia feita em 08/11/2026 00:17), **não** o tamanho do DB ao vivo — o DB vivo já está em ~3,27 GB e cresce com o uso.

**Como comprovar (snapshot do backup da T1):**

```bash
stat -c '%s %n' \
  ~/.local/share/opencode/opencode.db \
  ~/.local/share/opencode/opencode.db-wal
du -sh ~/.local/share/opencode
```

**Resultado esperado — snapshot do backup da T1 (08/11/2026 00:17):**

```text
3268820992  /root/.local/share/opencode/opencode.db      # snapshot do backup da T1 — 3.268.820.992 B (~3,0 GiB)
240467952   /root/.local/share/opencode/opencode.db-wal  # ~230 MB (~229 MiB)
3.4G        /root/.local/share/opencode                  # total do diretório
```

**Como comprovar (tamanho atual do DB ao vivo):**

```bash
stat -c '%s' ~/.local/share/opencode/opencode.db
```

**Resultado esperado:** valor ≥ `3268820992` (cresce com o uso).

**Proveniência:** snapshot do backup da T1 em 08/11/2026 00:17. Reexecute `stat` para o valor atual — o DB cresce com o uso.

---

## 11. Instalação do V2 no Termux/proot

**O que muda:** o Node do Termux reporta `os.platform() === "android"` e `process.platform === "android"`. O `postinstall` de `@opencode/cli` usa `os.platform()` para escolher o pacote de plataforma, e o `npm-install-checks` do npm aborta a instalação com `EBADPLATFORM` quando `process.platform === "android"`. Instalar o V2 direto no Termux, sem shim e sem `--force`, falha.

**Como comprovar (receita de instalação):**

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

**Armadilha 1 — `EBADPLATFORM`:** sem `--force`, o `npm-install-checks` aborta a instalação com `EBADPLATFORM`, porque `process.platform === "android"`. O `--force` contorna esse gate — mas o npm **ignora `--force` ao resolver `optionalDependencies`**, então a dep de plataforma (`@opencode/cli-linux-arm64@2.0.32`) precisa ser pedida **explicitamente** na mesma invocação.

**Armadilha 2 — `postinstall` resolve `android-arm64`:** o `postinstall` de `@opencode/cli` chama `os.platform()`; no Termux isso devolve `"android"`, e o pacote `android-arm64` correspondente não existe no registry. O shim (`os.platform = () => "linux"`) faz o postinstall escolher `linux-arm64`. O shim precisa existir **antes** do primeiro `npm install`, porque o postinstall roda durante a instalação.

**Regra do pin exato:** instalar sempre `@opencode/cli@2.0.32` **e** `@opencode/cli-linux-arm64@2.0.32`. Nunca `@latest` (ver seção 8 — o número deriva com o tempo) e nunca `@next` (beta mais antigo que o GA, sem `debug paths`).

**Atenção — escopo do `NODE_OPTIONS`:** `NODE_OPTIONS` é **escopo desta invocação** (`NODE_OPTIONS="--require $SHIM" npm install ...`). **Nunca** `export NODE_OPTIONS=...` no `setup.sh`/`.bashrc`: o shim faz monkeypatch global de `os.platform` e faria todo processo Node do device reportar `linux`, mascarando o gate `EBADPLATFORM` do npm.

**Proveniência:** receita executada e validada em 08/11/2026 na T3 (prefixo `/data/data/com.termux/files/usr/opt/opencode-v2/`); armadilhas `EBADPLATFORM` e `android-arm64` observadas durante a instalação.

---

## 12. Fatos operacionais do V2 no device: `service.json`, log compartilhado, cmdline do serviço e senha fora do repo

### 12.1 `service.json` grava a senha do serviço em texto claro **dentro do repo**

**O que muda:** ao autostartar o serviço compartilhado, o V2 grava `~/.config/opencode/service.json` contendo a senha do serviço em **texto claro**. Como `~/.config/opencode` é um **symlink** para `.config/opencode/` **dentro do repo**, esse arquivo cai **dentro do repositório versionado**. O `opencode2 service stop` **não** o remove — é preciso removê-lo manualmente.

**Como comprovar:**

```bash
# 1) Dispara o autostart do serviço compartilhado
mkdir -p /data/data/com.termux/files/usr/tmp/v2poc
OPENCODE_DB="/data/data/com.termux/files/usr/tmp/v2poc/test.db" opencode2 debug config > /dev/null

# 2) O arquivo existe dentro do repo (via symlink)
ls -la ~/.config/opencode/service.json
ls -la /root/Projetos/opencode_termux/.config/opencode/service.json

# 3) Conteúdo: senha em texto claro (NÃO imprimir em log público)
cat ~/.config/opencode/service.json
# esperado: {"password":"<senha de 32 bytes, texto claro>"}

# 4) O stop NÃO remove o arquivo
opencode2 service stop
ls -la ~/.config/opencode/service.json   # ainda existe

# 5) Limpeza manual obrigatória
rm -f ~/.config/opencode/service.json
```

**Mitigação no repo:** `.gitignore` **da raiz** contém `.config/opencode/service.json` (garantia repo-wide, inclusive em clone novo); o `.config/opencode/.gitignore` local é redundante e local-only. Os stop scripts (T10) removem `rm -f "$CONFIG_DIR/service.json"` **após** `opencode2 service stop`.

**Proveniência:** verificado em 08/11/2026 — arquivo criado com `{"password":"…"}` (64 B), `opencode2 service stop` encerrou o serviço (0 processos residuais) e o arquivo **permaneceu**.

### 12.2 O log do V2 é compartilhado com o V1 — `OPENCODE_DB` isola o DB, **não** o log

**O que muda:** `OPENCODE_DB` isola **apenas o banco**. O V2 continua escrevendo no **mesmo** arquivo de log do V1: `~/.local/share/opencode/log/opencode.log` (mesmo inode). Logo, durante o PoC lado a lado, o log do V2 aparece **misturado** com o log do V1.

**Como comprovar:**

```bash
# inode do log compartilhado
stat -c '%i %n' ~/.local/share/opencode/log/opencode.log

# fds do processo V2 (serve com OPENCODE_DB isolado)
ls -l /proc/<pid>/fd | grep -E 'opencode.*\.db|opencode\.log'
```

**Resultado esperado (medido em 08/11/2026):**

```text
# fds de DB: SOMENTE os do DB isolado — NENHUM fd para o DB real do V1
1 /data/data/com.termux/files/usr/tmp/v2poc/routes.db
1 /data/data/com.termux/files/usr/tmp/v2poc/routes.db-wal
1 /data/data/com.termux/files/usr/tmp/v2poc/routes.db-shm

# fd de log: o MESMO log do V1 (inode compartilhado)
8 -> /root/.local/share/opencode/log/opencode.log
```

> **Nota de path:** dentro do proot, `/tmp` é o **mesmo arquivo** que
> `/data/data/com.termux/files/usr/tmp` no Termux — o bind `--shared-tmp` faz
> essa equivalência (`/tmp` do proot ≡ `$PREFIX/tmp` do Termux). Por isso os
> caminhos são canônicos no **Termux**: `/tmp/v2poc/...` e
> `/data/data/com.termux/files/usr/tmp/v2poc/...` são o **mesmo** arquivo, e
> `$TMPDIR` **não existe** dentro do proot (a variável não é exportada lá).
> Use sempre o path absoluto Termux nos comandos.

**Proveniência:** verificado em 08/11/2026 via `/proc/<pid>/fd` do `serve` do V2 com `OPENCODE_DB` isolado; o inode do log (`1176222`) é o mesmo do processo V1.

### 12.3 O cmdline do serviço compartilhado não casa com `opencode serve` nem `opencode2`

**O que muda:** dentro do proot (que roda com `--link2symlink`), o serviço compartilhado do V2 aparece na tabela de processos como:

```text
/.l2s/.l2s.opencode0001.0002 serve --service
```

Esse cmdline **não** contém `opencode serve` nem `opencode2` — um `grep` por esses nomes reportaria `0` (falso negativo) e deixaria o serviço vivo. O padrão correto de detecção é:

```bash
ps -eo pid,args | grep -cE "[s]erve --service|[o]pencode2 serve"
# esperado: 0 após o stop
```

**Como comprovar:**

```bash
# Com o serviço de pé
ps -eo pid,args | grep -E "[s]erve --service|[o]pencode2 serve"
# esperado: /.l2s/.l2s.opencode0001.0002 serve --service

# Comando canônico de parada
opencode2 service stop
opencode2 service status
```

**Proveniência:** verificado em 08/11/2026 — PID 20984 com cmdline `/.l2s/.l2s.opencode0001.0002 serve --service`; `opencode2 service status` reportou `http://127.0.0.1:49374`.

### 12.4 Decisão: a senha do servidor vive **fora do repo**

**Decisão:** a senha do servidor do V2 **não** fica no repositório. Ela é gerada/persistente em `$PREFIX/tmp/opencode_password.txt` (chmod 600) e lida pelos launchers (`run-*.sh`) e pelos wrappers Termux (`bin/opencode-*.sh`).

**Consequências:**

- O `.env` (versionado) **não** recebe a senha — `.env.example` declara `OPENCODE_PASSWORD=` **vazio**, apenas como placeholder documentado.
- O `.env` real passa a ser **ignorado** pelo git (o `.gitignore` da raiz contém `.env`); o `git rm --cached .env` é feito pelo agente `git-commit` no momento do commit.
- O `service.json` do V2 (seção 12.1) é a outra via de vazamento de segredo dentro do repo — precisa estar no `.gitignore` e ser removido no stop.

**Proveniência:** decisão do usuário em 08/11/2026; registrada no plano (T8/T10) e no ADR da T16.

---

## Referências

- Plano: `.opencode/plans/20261022_1023_migracao-opencode-2.0.md`
- Evidência do binário V2 extraído: `/tmp/opencode/v2inspect/` (`strings.txt`, `package/bin/opencode`)
- ADR da migração: `docs/decisions/ADR-010-migracao-opencode-v2-ga.md` (criado na T16)
