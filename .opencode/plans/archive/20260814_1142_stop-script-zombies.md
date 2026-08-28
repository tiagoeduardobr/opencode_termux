# Plano: Melhoria do stop script — limpeza de órfãos e zumbis (`bin/opencode-web-stop.sh`)

## Objetivo

O `bin/opencode-web-stop.sh` atualmente mata apenas o PID do proot guardado em `$PID_FILE`. Na prática isso deixa órfãos: processos dentro do proot (`run-cloudflare-tunnel.sh`, `opencode web`, `cloudflared tunnel`) sobrevivem à morte do proot, além de zumbis `<defunct>` que não podem ser mortos por `kill`.

**Resultado esperado**: o stop script deve (1) matar o proot (graceful → force), (2) limpar processos internos sobreviventes por padrões específicos e seguros, (3) tratar zumbis corretamente (reportar; reaped pelo init quando o pai morre), (4) carregar `.env` para conhecer `OPENCODE_PORT`, e (5) verificar e reportar remanescentes ao final.

## Escopo

- **Dentro**: reescrever `bin/opencode-web-stop.sh` (único arquivo).
- **Fora**:
  - `bin/opencode-web.sh` e `run-cloudflare-tunnel.sh` (não alterar — apenas leitura para referência)
  - `bin/opencode-tailscale-stop.sh` (mesmo problema de órfãos, mas fora de escopo — follow-up futuro)
  - `.env.example` (sem variável nova; reusa `OPENCODE_PORT`/`OPENCODE_HOSTNAME`)
  - README/AGENTS.md/docs (sem alteração obrigatória; follow-up opcional)

## Contexto / Diagnóstico (evidências coletadas no ambiente real em 2026-08-14)

Estado observado com `ps aux` (host Termux enxerga processos do proot — proot não isola a tabela de processos):

| PID | PPID | Stat | Processo |
|---|---|---|---|
| 10796 | 1 | R | `proot ... --kill-on-exit ... /bin/bash -c 'cd "$1" && exec ./run-cloudflare-tunnel.sh'` (proot órfão, PPID=1) |
| 10821 | 10796 | S | `bash .../run-cloudflare-tunnel.sh` (vivo, dentro do proot) |
| 10824 | 10821 | Rl | `opencode web --hostname 127.0.0.1 --port 4096` |
| 11030 | 10821 | Sl | `cloudflared tunnel --url http://127.0.0.1:4096` |
| 25579 | 1 | R | `bash .../run-cloudflare-tunnel.sh` (ÓRFÃO reparentado para init, alto CPU) |
| 25615 | 25579 | Z | `[cloudflared] <defunct>` (ZUMBI) |

Fatos empiricamente confirmados (comandos testados no ambiente):

1. **Zumbi não morre com kill**: `kill -0 25615` → exit 0 (existe na tabela); `kill -9 25615` → exit 0 mas **não mata** (no-op). `ps -o stat= -p 25615` → `Z`.
2. **Órfão reparentado**: `25579` tem `PPID=1`; seu filho zumbi `25615` tem `PPID=25579` → matar `25579` permite o init reapar `25615`.
3. **`pkill -f` no host enxerga processos do proot** (cmdline completa visível).
4. **`pkill -f "run-cloudflare-tunnel.sh"` também casa o proot** (cmdline do proot contém o nome) → matar o proot por PID primeiro é o caminho limpo; o pattern-kill cobre o resto.
5. **`lsof -ti :4096` pode retornar vazio** mesmo com `opencode web` escutando (neste sandbox: `Permission denied` em `/proc/net/tcp`; `fuser 4096/tcp` idem). No device real o `lsof` do proot funciona (já usado em `run-cloudflare-tunnel.sh`), mas o plano deve tratar como best-effort com fallback e nunca como mecanismo único.
6. **Self-match do `pgrep -f` em comandos inline**: `pgrep -f 'cloudflared tunnel'` casa até o `bash -c` que está rodando o teste. No script real (cmdline `bash .../opencode-web-stop.sh`) **não há self-match**, mas os comandos de verificação do plano devem estar cientes.
7. O proot é iniciado com `--kill-on-exit` (confirmado no cmdline real), **mas isso não garante** a morte dos filhos (evidência: órfãos existem) → limpeza explícita por padrão é necessária.

## Assumptions

1. O script roda no host Termux (`$PREFIX` definido); `ps`/`pgrep`/`pkill` do host enxergam os processos do proot (confirmado).
2. Padrões de kill são específicos o suficiente para não matar processos não relacionados:
   - `run-cloudflare-tunnel.sh` — script exclusivo deste repo;
   - porta `$OPENCODE_PORT` (via `lsof`/`fuser`) — cobre `opencode web` sem `pkill -f "opencode web"` genérico (evita matar sessão TUI do opencode em outro terminal);
   - `cloudflared tunnel --url http://127.0.0.1:${PORT}` — padrão com a porta evita matar outros tunnels.
3. `lsof` pode não existir/no-op no device → fallback `fuser`; se ambos indisponíveis ou cegos, o caminho principal é o SIGTERM no `run-cloudflare-tunnel.sh` (trap `cleanup` mata `$OPENCODE_PID` e `$CLOUDFLARED_PID`); remanescentes são reportados no final.
4. Zumbis não podem ser mortos (`kill -0`=0, `kill -9` no-op); morrem quando o pai morre → o script mata os pais vivos e reporta zumbis como INFO (reap pelo init).
5. `PID_FILE` pode não existir **ou** apontar para PID morto/zumbi (cenário real: proot morreu, órfãos ficaram) → a limpeza por padrão DEVE rodar sempre, inclusive sem `PID_FILE` (decisão justificada: foi exatamente o cenário real observado).
6. `.env` é carregado de `$SCRIPT_DIR` (raiz do repo), mesma convenção do `opencode-web.sh`.
7. Convenções do AGENTS.md mantidas: shebang `#!/data/data/com.termux/files/usr/bin/bash`, `set -uo pipefail` (sem `-e`), graceful kill → espera 3×1s → kill -9, `stty sane` (quirk Termux), `termux-wake-unlock`.

## Dependências

- **Pré-requisitos**: `ps` com suporte a `-o stat=` (procps no Termux — já confirmado), `pkill`/`pgrep` (procps ou busybox), `lsof` ou `fuser` (best-effort).
- **Ordem**: Tasks 1→4 sequenciais (cada uma adiciona um bloco no mesmo arquivo).

## Design da Solução (visão geral do fluxo do novo stop script)

```
1. SCRIPT_DIR + source .env (se existir) + defaults (PID_FILE, NOTIFY_FILE, LOG_FILE, PORT, HOSTNAME)
2. Definir padrões: SCRIPT_PATTERN='run-cloudflare-tunnel.sh'
                       CLOUDFLARED_PATTERN="cloudflared tunnel --url http://127.0.0.1:${PORT}"
3. Helpers: is_zombie() (ps -o stat= → 'Z'), kill_graceful(), port_pids() (lsof → fuser fallback)
4. PID_FILE existe?
   - PID não roda        → [WARN] segue para limpeza de órfãos
   - PID é zumbi          → [WARN] não pode ser morto; será reaped pelo init; segue
   - PID válido           → [INFO] Parando servico (PID N)... + SIGTERM
   PID_FILE não existe    → [INFO] tentando limpar órfãos por padrão (NÃO exit 0 antes)
5. Fase A (graceful, sempre): SIGTERM em todos os alvos:
   - PID do proot (se válido/não-zumbi)
   - pkill -TERM -f "$SCRIPT_PATTERN"
   - pkill -TERM -f "$CLOUDFLARED_PATTERN"
   - kill $(port_pids)  (SIGTERM)
   → espera até 3×1s enquanto houver alvo vivo não-zumbi (break se nada vivo)
6. Fase B (force, sempre): SIGKILL nos sobreviventes (mesmos 4 alvos)
7. Verificação final: coletar remanescentes (script pattern, cloudflared pattern, port_pids)
   - zumbi → [INFO] será reaped pelo init
   - vivo  → [WARN] listar com ps; flag remanescente_alive=1
   - se remanescente_alive → [WARN] verificação manual
8. rm -f PID_FILE NOTIFY_FILE LOG_FILE; stty sane; termux-wake-unlock; [INFO] Servico parado. exit 0
```

Pontos-chave de segurança:
- **NUNCA** usar `pkill -f "opencode web"` genérico (risco TUI) — `opencode web` é matado via porta (`port_pids`) ou via trap do `run-cloudflare-tunnel.sh`.
- Todos os kills com `2>/dev/null || true` (set -uo sem -e; fallback é a norma).
- O proot é morto por PID antes dos patterns; o pattern do script também casaria o proot (inofensivo/descartável se já morto).
- Verificações finais com `pgrep -f` separados por padrão (evitar alternância de regex `|`, menos portável em busybox).

## Tasks

### Task 1: Carregar `.env` e definir defaults (SCRIPT_DIR, PORT, HOSTNAME)

- **Arquivo**: `bin/opencode-web-stop.sh` (modificar)
- **Descrição**: Adicionar `SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"`, carregar `$SCRIPT_DIR/.env` com `set -a; source; set +a` (mesmo padrão do `opencode-web.sh`), definir `PORT="${OPENCODE_PORT:-4096}"` e `HOSTNAME="${OPENCODE_HOSTNAME:-127.0.0.1}"`. Manter defaults atuais de `PID_FILE`/`NOTIFY_FILE`/`LOG_FILE`.
- **Complexidade**: baixa
- **Acceptance**:
  - `SCRIPT_DIR` calculado da raiz do repo (mesma convenção do start)
  - `.env` carregado antes dos defaults (se existir)
  - `PORT`/`HOSTNAME` derivados de `OPENCODE_PORT`/`OPENCODE_HOSTNAME` com fallback 4096/127.0.0.1
  - Shebang e `set -uo pipefail` intactos
- **Verification**:
  - Run: `bash -n bin/opencode-web-stop.sh`
  - Expected: exit code 0 (sem erro de sintaxe)
  - Run: `grep -q 'SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"' bin/opencode-web-stop.sh`
  - Expected: exit code 0
  - Run: `grep -q 'OPENCODE_PORT:-4096' bin/opencode-web-stop.sh` && `grep -q 'OPENCODE_HOSTNAME' bin/opencode-web-stop.sh`
  - Expected: exit code 0 (ambos)
  - Run: `head -1 bin/opencode-web-stop.sh`
  - Expected: `#!/data/data/com.termux/files/usr/bin/bash`

### Task 2: Helpers `is_zombie()` / `kill_graceful()` + tratamento do PID do proot

- **Arquivo**: `bin/opencode-web-stop.sh` (modificar)
- **Descrição**: Adicionar `is_zombie()` (usa `ps -o stat= -p "$1" | tr -d ' '` == `Z`) e `kill_graceful()` (SIGTERM → loop 3×1s com break se morto OU zumbi → SIGKILL se ainda vivo e não-zumbi). Reestruturar o bloco atual de kill do PID:
  - Se `kill -0 "$PID"` falhar → `[WARN] PID ... nao esta rodando.` (continua)
  - Se `is_zombie "$PID"` → `[WARN] PID ... e um processo zumbi; nao pode ser morto; sera reaped pelo init.` (continua)
  - Senão → mensagem `[INFO] Parando servico (PID ...)...` + kill_graceful
  - **Remover o `exit 0` do caminho "PID_FILE não existe"** — nesse caso logar e **continuar** para a limpeza de órfãos (Task 3). (Hoje dá `exit 0`; isso impede a limpeza no cenário real de órfãos sem PID_FILE.)
- **Complexidade**: média
- **Acceptance**:
  - Loop de espera quebra imediatamente se o processo virar zumbi (evita espera inútil de 3s e `kill -9` no-op em zumbi)
  - Convenção graceful → 3×1s → force mantida
  - Nenhum caminho faz `exit` antes da limpeza de órfãos
- **Verification**:
  - Run: `bash -n bin/opencode-web-stop.sh`
  - Expected: exit code 0
  - Run: `grep -q 'is_zombie' bin/opencode-web-stop.sh` && `grep -q 'kill_graceful' bin/opencode-web-stop.sh`
  - Expected: exit code 0 (ambos)
  - Run: `grep -q 'ps -o stat=' bin/opencode-web-stop.sh`
  - Expected: exit code 0
  - Run: `grep -n 'exit' bin/opencode-web-stop.sh`
  - Expected: sem `exit 0` no caminho "PID_FILE não encontrado" (pode ter `exit 0` apenas no fim do script)

### Task 3: Limpeza de órfãos por padrão (script + porta + cloudflared)

- **Arquivo**: `bin/opencode-web-stop.sh` (modificar)
- **Descrição**: Adicionar `port_pids()` (lsof primário: `lsof -ti :"$PORT" 2>/dev/null`; fallback fuser: `fuser -n tcp "$PORT" 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9]+$'`; se vazio/indisponível, logar `[WARN]` e seguir — o trap do script pai é o caminho principal). Implementar limpeza que roda **sempre**:
  - **Fase A (SIGTERM)**: `pkill -TERM -f "$SCRIPT_PATTERN"`; `pkill -TERM -f "$CLOUDFLARED_PATTERN"`; `kill` nos PIDs de `port_pids()`; tudo com `2>/dev/null || true`
  - **Espera**: até 3×1s enquanto existir alvo vivo não-zumbi (função de checagem por pgrep separado por padrão + port_pids + PID do proot); break se nada vivo
  - **Fase B (SIGKILL)**: mesmos alvos com `-9`
  - Padrão cloudflared **com a porta**: `cloudflared tunnel --url http://127.0.0.1:${PORT}` (evita matar outros tunnels)
- **Complexidade**: alta
- **Acceptance**:
  - Limpeza executa mesmo sem PID_FILE (cenário real de órfãos)
  - `opencode web` NUNCA é alvo de `pkill -f "opencode web"` genérico — apenas via porta ou via trap do script
  - Cada kill é idempotente e não falha o script (`|| true`)
  - Espera total ≈ 3s (não 9s+)
- **Verification**:
  - Run: `bash -n bin/opencode-web-stop.sh`
  - Expected: exit code 0
  - Run: `grep -q 'pkill.*\$SCRIPT_PATTERN' bin/opencode-web-stop.sh` && `grep -q 'SCRIPT_PATTERN=.*run-cloudflare-tunnel.sh' bin/opencode-web-stop.sh`
  - Expected: exit code 0 (implementação usa variável SCRIPT_PATTERN; literal presente na definição)
  - Run: `grep -q 'cloudflared tunnel --url http://127.0.0.1:' bin/opencode-web-stop.sh`
  - Expected: exit code 0
  - Run: `grep -q 'lsof -ti' bin/opencode-web-stop.sh` && `grep -q 'fuser' bin/opencode-web-stop.sh`
  - Expected: exit code 0 (fallback presente)
  - Run: `grep -c 'pkill -f "opencode web"' bin/opencode-web-stop.sh`
  - Expected: 0 (proibido)

### Task 4: Verificação final + cleanup + mensagens

- **Arquivo**: `bin/opencode-web-stop.sh` (modificar)
- **Descrição**: Após Fase B, coletar remanescentes (pgrep separado por padrão + port_pids) e classificar:
  - `is_zombie "$p"` → `[INFO] Zumbi PID p sera reaped pelo init.`
  - senão → `[WARN] Processo remanescente: <ps -o pid,args -p p>` e marcar `remaining_alive=1`
  - Se `remaining_alive=1` → `[WARN] Ha processos remanescentes. Verifique manualmente.`
  - Sem remanescentes → `[INFO] Nenhum processo remanescente.`
  Manter `rm -f "$PID_FILE" "$NOTIFY_FILE" "$LOG_FILE"`, `stty sane 2>/dev/null || true`, `termux-wake-unlock 2>/dev/null || true`, mensagem final `[INFO] Servico parado.` e `exit 0`.
- **Complexidade**: baixa
- **Acceptance**:
  - Zumbis não geram WARN de remanescente (INFO, reap pelo init)
  - Arquivos temporários removidos
  - `stty sane` e `termux-wake-unlock` presentes (quirk Termux não removido)
  - Exit code 0 em todos os caminhos
- **Verification**:
  - Run: `bash -n bin/opencode-web-stop.sh`
  - Expected: exit code 0
  - Run: `grep -q 'Processo remanescente' bin/opencode-web-stop.sh`
  - Expected: exit code 0
  - Run: `grep -q 'stty sane' bin/opencode-web-stop.sh` && `grep -q 'termux-wake-unlock' bin/opencode-web-stop.sh`
  - Expected: exit code 0 (ambos)
  - Run: `grep -q 'rm -f "\$PID_FILE" "\$NOTIFY_FILE" "\$LOG_FILE"' bin/opencode-web-stop.sh`
  - Expected: exit code 0

## Riscos

| Risco | Mitigação |
|---|---|
| `pkill -f` self-match em comandos de verificação inline (`bash -c`) | No script real a cmdline é `bash .../opencode-web-stop.sh` (não contém os padrões) — sem self-match. Comandos de verificação usam padrões distintos ou checam com `ps`. |
| `pkill -f "run-cloudflare-tunnel.sh"` também casa o proot (cmdline contém o nome) | Proot é morto por PID na Task 2 antes dos patterns; se ainda vivo, matar é desejável (mesmo serviço). |
| `lsof`/`fuser` cegos ou ausentes no device (`Permission denied` em `/proc/net/tcp` observado no sandbox) | Best-effort: `port_pids()` com fallback fuser; caminho principal é SIGTERM no `run-cloudflare-tunnel.sh` (trap mata opencode+cloudflared); remanescentes vão para WARN final. |
| Zumbi persiste se o init do device não reap | Reportar como INFO; fora do controle do script (reap depende do init/reboot). Não bloquear o stop. |
| Matar processo não relacionado na mesma porta | Porta é do projeto e configurável (`OPENCODE_PORT`); risco baixo e aceitável (mesmo comportamento do `run-cloudflare-tunnel.sh`). |
| Quebrar o fluxo start→stop normal | Verificação Final exige teste integrado completo (cenários 1–4) antes de commitar. |
| Alternância de regex `|` em `pgrep -f` pouco portátil (busybox) | Verificações usam `pgrep -f` separados por padrão, sem alternância. |

## Ordem de Implementação

1. **Task 1** — `.env` + defaults (base para tudo)
2. **Task 2** — helpers + kill do proot zombie-aware (remove `exit 0` precoce)
3. **Task 3** — limpeza de órfãos por padrão (núcleo da melhoria)
4. **Task 4** — verificação final + cleanup + mensagens
5. **Verificação Final** — testes integrados no device

## Verificação Final

```bash
# 1. Sintaxe e invariantes
bash -n bin/opencode-web-stop.sh
head -1 bin/opencode-web-stop.sh          # shebang Termux
grep -c 'pkill -f "opencode web"' bin/opencode-web-stop.sh   # = 0

# 2. Cenário 1 — stop normal (nada sobrando)
opencode_web                              # sobe serviço
sleep 10
opencode_web_stop                         # roda o stop
ps aux | grep -E 'run-cloudflare-tunnel|opencode web|cloudflared' | grep -v grep
# Expected: nenhuma linha (ou apenas INFO de zumbi reaped; esperar 2s e re-checar)
# Expected: saída do stop termina com "[INFO] Servico parado." e exit 0

# 3. Cenário 2 — reprodução do bug real (órifos + zumbis)
opencode_web
sleep 10
kill -9 "$(cat "$PREFIX/tmp/opencode_web.pid")"     # mata só o proot (deixa órfãos)
sleep 3
ps aux | grep -E 'run-cloudflare-tunnel|opencode web|cloudflared' | grep -v grep
# Expected: órifos/duplicados visíveis (run-cloudflare-tunnel.sh, opencode web, cloudflared; possivelmente zumbi <defunct>)
opencode_web_stop
ps aux | grep -E 'run-cloudflare-tunnel|opencode web|cloudflared' | grep -v grep
# Expected: nenhum processo vivo; zumbis <defunct> podem aparecer como "[INFO] Zumbi ... sera reaped pelo init." e somem em 2-3s (reap pelo init)
# Expected: exit 0

# 4. Cenário 3 — dry run sem serviço rodando
opencode_web_stop
# Expected: "[INFO] PID file nao encontrado..." (ou "[WARN] PID ... nao esta rodando.") + limpeza de órfãos não encontra nada + exit 0

# 5. Cenário 4 — porta custom
OPENCODE_PORT=5000 opencode_web
sleep 10
OPENCODE_PORT=5000 opencode_web_stop
ps aux | grep -E 'run-cloudflare-tunnel|opencode web|cloudflared' | grep -v grep
# Expected: nada remanescente (padrões usam a porta 5000)

# 6. Outros scripts intactos (fora de escopo)
bash -n bin/opencode-web.sh run-cloudflare-tunnel.sh bin/opencode-tailscale-stop.sh
```

**Critérios de sucesso (resumo)**:
- Stop limpa proot + órfãos por padrão (script, porta, cloudflared-com-porta) em todos os cenários acima.
- Zumbis são reportados como INFO e reaped pelo init após morte do pai (nunca bloqueiam o script).
- `OPENCODE_PORT` custom é respeitado (Cenário 4).
- Exit 0 em todos os caminhos; `stty sane` + `termux-wake-unlock` preservados; `pkill -f "opencode web"` ausente.
- Nenhuma alteração em `opencode-web.sh`, `run-cloudflare-tunnel.sh`, `.env.example`.

## Notas de Implementação

- Manter `set -uo pipefail` (sem `-e`): o fallback é por design; cada comando destrutivo é guardado com `2>/dev/null || true`.
- Não usar `kill -0` como único teste de vida: para zumbis retorna 0 → sempre combinar com `is_zombie`.
- Se shellcheck estiver disponível no device: `shellcheck -x bin/opencode-web-stop.sh` (opcional; o repositório não exige).
- Backlog (`docs/PROJECT_BACKLOG_*.md`): o repo não possui arquivo de backlog hoje; se um for criado depois, registrar esta tarefa como `TODO-B-NN` conforme o padrão do AGENTS.md.
