# Plano: Limpeza do DB e cache do OpenCode (limpeza total)

> **Data**: 16/09/2026 · **Autor**: task-planner
> **Decisão do usuário**: NÃO manter nenhuma sessão (limpeza total) + deletar
> eventos de replay. Backup de segurança é obrigatório antes de qualquer deleção.

## Objetivo

Reduzir o footprint de dados do OpenCode no device de **~3.9 GB para ~10 MB**
(≈99.7% de redução), eliminando:
- `opencode.db` (3.6 GB — tabela `event` com 3.1 GB de eventos de replay)
- `opencode.db-wal` (264 MB — Write-Ahead Log não consolidado)
- `log/opencode.log` (36 MB)
- `snapshot/` (82 MB — git repos de snapshot)
- `tool-output/` (1.7 MB)
- `~/.cache/opencode/` (12 MB — models.json + temp órfão)

**Sem tocar** no repo versionado (`~/.config/opencode/` = symlink para
`opencode_termux/.config/opencode/`), credenciais (`auth.json`, `account.json`),
nem no binário do opencode.

## Escopo

- **Dentro**:
  - `~/.local/share/opencode/opencode.db` + `-wal` + `-shm` (SQLite)
  - `~/.local/share/opencode/log/opencode.log`
  - `~/.local/share/opencode/snapshot/` (git repos de snapshot)
  - `~/.local/share/opencode/tool-output/`
  - `~/.cache/opencode/models.json` + `models.json.*.tmp`
  - `~/.local/state/opencode/prompt-history.jsonl` (opcional, privacidade)
- **Fora**:
  - `~/.config/opencode/` (repo versionado — NUNCA limpar)
  - `~/.local/share/opencode/auth.json` e `account.json` (credenciais)
  - `~/.local/share/opencode/repos/` (3.5 KB — insignificante)
  - `~/.cache/opencode/bin/rg` (binário ripgrep do opencode)
  - `~/.cache/opencode/packages/` (plugins instalados)
  - `/tmp/opencode/` (20 MB — tmp compartilhado do proot, NÃO é do opencode)
  - Qualquer arquivo do repo `opencode_termux` (scripts, docs, config)

## Assumptions

1. O usuário quer **limpeza total**: todas as 1.109 sessões serão deletadas.
2. Backup de segurança é obrigatório (Task 2) — o usuário pode restaurar se mudar de ideia.
3. O opencode **não está rodando** durante a limpeza (ou será parado antes).
4. `opencode db "<query>"` aceita SQL arbitrário (verificado: `SELECT`, `PRAGMA` funcionam).
5. `VACUUM INTO` é suportado pelo SQLite embutido do opencode (better-sqlite3, SQLite 3.27+).
6. Tabelas com FK `ON DELETE CASCADE` para `session`: `message`, `part`, `todo`, `session_context_epoch`.
7. Tabelas **sem** cascade para `session`: `event` e `event_sequence` (FK via `aggregate_id`) — precisam deleção explícita.
8. `event.aggregate_id` = `session.id` (verificado: 1.109 aggregates = 1.109 sessões, 0 órfãos).
9. `~/.cache/opencode/models.json` é recriado automaticamente pelo opencode.
10. Snapshots em `snapshot/` são recriados automaticamente quando um projeto é aberto.

## Dependências

### Matriz de Dependências

| Task | Depende de | Premissa |
|------|-----------|----------|
| Task 1 (pre-flight) | — | Confirma estado atual antes de qualquer mudança |
| Task 2 (backup) | Task 1 | Backup deve capturar o estado pré-limpeza |
| Task 3 (checkpoint WAL) | Task 2 | Checkpoint consolida WAL no DB principal (backup já feito) |
| Task 4 (deletar events) | Task 3 | Libera 3.1 GB — maior ganho; FK exige deletar `event` antes de `event_sequence` |
| Task 5 (deletar sessions) | Task 4 | Cascade remove message/part/todo/session_context_epoch |
| Task 6 (VACUUM) | Task 4, Task 5 | Compacta arquivo de 3.6 GB para ~10 MB |
| Task 7 (logs) | Task 6 | Independente do DB — pode ser paralela a 4-6 |
| Task 8 (tool-output) | Task 6 | Independente do DB — pode ser paralela a 4-6 |
| Task 9 (cache) | Task 6 | Independente do DB — pode ser paralela a 4-6 |
| Task 10 (snapshots) | Task 6 | Opcional — deleta git repos de snapshot |
| Task 11 (verificação) | Todas | Confirma opencode funcional pós-limpeza |

**Regra**: Tasks 7, 8, 9 são independentes entre si e do DB → podem rodar em paralelo com 4-6.
Task 11 é somente leitura e depende de todas.

### Pré-requisitos

- OpenCode **parado** (sem TUI, sem `opencode web`, sem `opencode serve` rodando).
  Verificar com: `pgrep -f "opencode"` → nenhum processo além do shell atual.
- Espaço em disco suficiente para o backup (~4 GB livres; o backup via `VACUUM INTO`
  cria um arquivo do tamanho dos dados atuais, ~3.6 GB).
- `du` e `date` disponíveis (coreutils do proot).

## Tasks

### Task 1: Pre-flight — medir estado atual e confirmar opencode parado

- **Acceptance**: Given o estado atual do device, When rodamos os comandos de
  diagnóstico, Then obtemos os valores esperados documentados abaixo.
- **Verify**:
  - Run: `du -sh ~/.local/share/opencode/ ~/.cache/opencode/`
  - Expected: `3.9G` e `12M` (valores de referência; variações pequenas ok)
  - Run: `opencode db "SELECT COUNT(*) FROM session;"`
  - Expected: `1109` (ou valor próximo)
  - Run: `pgrep -f "opencode" | grep -v $$ || echo "nenhum processo opencode"`
  - Expected: `nenhum processo opencode` (ou apenas o shell atual)
- **Files**: nenhum (somente leitura)
- **Complexidade**: baixa

### Task 2: Backup de segurança (obrigatório — nunca pular)

- **Acceptance**: Given o DB atual, When criamos o backup via `VACUUM INTO` e
  copiamos os arquivos auxiliares, Then o backup existe e é verificável
  (abre sem erro e contém as 1.109 sessões).
- **Verify**:
  - Run: `mkdir -p ~/opencode-backup-20260916 && opencode db "VACUUM INTO '/root/opencode-backup-20260916/opencode.db.backup';"`
  - Expected: sem erro; arquivo criado
  - Run: `ls -lh ~/opencode-backup-20260916/opencode.db.backup`
  - Expected: arquivo de ~3.6 GB presente
  - Run: `opencode db "SELECT COUNT(*) FROM session;"` (no backup — abrir com
    `sqlite3` se disponível, ou via `opencode db` apontando para o backup)
  - Expected: `1109` sessões no backup
  - Run: `cp ~/.local/share/opencode/opencode.db-wal ~/.local/share/opencode/opencode.db-shm ~/opencode-backup-20260916/ 2>/dev/null; echo "wal+shm copiados (se existirem)"`
  - Expected: `wal+shm copiados (se existirem)`
- **Files**: `~/opencode-backup-20260916/` (fora do repo)
- **Complexidade**: média
- **Nota**: Se `VACUUM INTO` falhar (SQLite antigo), fallback: parar opencode e
  copiar `opencode.db` + `-wal` + `-shm` diretamente com `cp`.

### Checkpoint 1: Backup verificado

- Verificar: backup existe e contém 1.109 sessões
- Validação: `ls -lh ~/opencode-backup-20260916/` mostra o `.db.backup` de ~3.6 GB
- **Se o backup falhar ou não for verificável, PARAR — não prosseguir.**

### Task 3: Checkpoint do WAL (consolidar 264 MB)

- **Acceptance**: Given o WAL com 264 MB, When rodamos `wal_checkpoint(TRUNCATE)`,
  Then o WAL é consolidado no DB principal e truncado.
- **Verify**:
  - Run: `opencode db "PRAGMA wal_checkpoint(TRUNCATE);"`
  - Expected: `0|N|N` (busy=0, log=0, checkpointed=N) — sem erro
  - Run: `ls -lh ~/.local/share/opencode/opencode.db-wal`
  - Expected: tamanho reduzido (idealmente 0 bytes ou próximo)
- **Files**: `~/.local/share/opencode/opencode.db-wal`
- **Complexidade**: baixa

### Task 4: Deletar eventos de replay (libera ~3.1 GB)

- **Acceptance**: Given a tabela `event` com 274.866 linhas (3.1 GB), When
  deletamos todos os eventos e sequences, Then as tabelas ficam vazias.
- **Verify**:
  - Run: `opencode db "DELETE FROM event;"`
  - Expected: sem erro (deleta ~274.866 linhas)
  - Run: `opencode db "DELETE FROM event_sequence;"`
  - Expected: sem erro (deleta 1.109 linhas)
  - Run: `opencode db "SELECT COUNT(*) FROM event; SELECT COUNT(*) FROM event_sequence;"`
  - Expected: `0` e `0`
- **Files**: `~/.local/share/opencode/opencode.db` (tabelas `event`, `event_sequence`)
- **Complexidade**: baixa
- **Nota**: Ordem importa — `event` referencia `event_sequence` via FK. Deletar
  `event` primeiro, depois `event_sequence`.

### Task 5: Deletar todas as sessões (cascade para message/part/todo)

- **Acceptance**: Given 1.109 sessões no DB, When deletamos todas via SQL,
  Then session/message/part/todo/session_context_epoch ficam vazias.
- **Verify**:
  - Run: `opencode db "DELETE FROM session;"`
  - Expected: sem erro (cascade remove message 17.615, part 84.767, todo 63,
    session_context_epoch 0)
  - Run: `opencode db "SELECT (SELECT COUNT(*) FROM session) || '|' || (SELECT COUNT(*) FROM message) || '|' || (SELECT COUNT(*) FROM part) || '|' || (SELECT COUNT(*) FROM todo);"`
  - Expected: `0|0|0|0`
- **Files**: `~/.local/share/opencode/opencode.db` (tabelas `session`, `message`,
  `part`, `todo`, `session_context_epoch`)
- **Complexidade**: baixa
- **Nota**: Fallback oficial: `opencode session list` + `opencode session delete <id>`
  em loop (1.109 comandos — lento, usar apenas se o SQL falhar).

### Task 6: VACUUM — compactar o arquivo de 3.6 GB

- **Acceptance**: Given o DB com dados deletados (freelist cheia), When rodamos
  `VACUUM`, Then o arquivo físico é compactado para ~10 MB.
- **Verify**:
  - Run: `opencode db "VACUUM;"`
  - Expected: sem erro
  - Run: `ls -lh ~/.local/share/opencode/opencode.db`
  - Expected: ~10 MB (antes: 3.6 GB)
  - Run: `opencode db "PRAGMA freelist_count;"`
  - Expected: `0` (sem páginas livres)
- **Files**: `~/.local/share/opencode/opencode.db`
- **Complexidade**: média
- **Nota**: VACUUM não roda dentro de transação — `opencode db` executa queries
  individuais, então funciona. Se falhar por lock, confirmar que o opencode está parado.

### Checkpoint 2: DB limpo e compactado

- Verificar: `opencode.db` ≤ 20 MB e todas as tabelas de dados vazias
- Validação: `ls -lh ~/.local/share/opencode/opencode.db` + query de contagem
- **Se o DB não compactar, investigar antes de prosseguir.**

### Task 7: Truncar log (libera 36 MB)

- **Acceptance**: Given `log/opencode.log` com 36 MB, When truncamos, Then o
  arquivo fica com 0 bytes.
- **Verify**:
  - Run: `truncate -s 0 ~/.local/share/opencode/log/opencode.log`
  - Expected: sem erro
  - Run: `ls -lh ~/.local/share/opencode/log/opencode.log`
  - Expected: `0` bytes
- **Files**: `~/.local/share/opencode/log/opencode.log`
- **Complexidade**: baixa
- **Nota**: Alternativa: `: > ~/.local/share/opencode/log/opencode.log` (equivalente).

### Task 8: Limpar tool-output (libera 1.7 MB)

- **Acceptance**: Given `tool-output/` com 1.7 MB de outputs de tools, When
  deletamos os arquivos, Then o diretório fica vazio.
- **Verify**:
  - Run: `rm -f ~/.local/share/opencode/tool-output/tool_*`
  - Expected: sem erro
  - Run: `du -sh ~/.local/share/opencode/tool-output/`
  - Expected: `0` ou `4.0K` (diretório vazio)
- **Files**: `~/.local/share/opencode/tool-output/`
- **Complexidade**: baixa

### Task 9: Limpar cache de providers (libera ~8 MB)

- **Acceptance**: Given `~/.cache/opencode/` com models.json (4.6 MB) e temp
  órfão (3.2 MB), When deletamos os arquivos de cache, Then o diretório mantém
  apenas `bin/` e `packages/`.
- **Verify**:
  - Run: `rm -f ~/.cache/opencode/models.json ~/.cache/opencode/models.json.*.tmp`
  - Expected: sem erro
  - Run: `ls -la ~/.cache/opencode/`
  - Expected: apenas `bin/`, `packages/` (models.json será recriado na próxima execução)
- **Files**: `~/.cache/opencode/models.json`, `~/.cache/opencode/models.json.*.tmp`
- **Complexidade**: baixa
- **Nota**: NÃO deletar `bin/rg` (binário ripgrep) nem `packages/` (plugins).

### Task 10: Limpar snapshots de git (libera até 82 MB) — OPCIONAL

- **Acceptance**: Given `snapshot/` com 82 MB de git repos, When deletamos os
  snapshots de projetos não mais ativos, Then o diretório fica com apenas o
  snapshot do projeto ativo (ou vazio, se o usuário preferir limpeza total).
- **Verify**:
  - Run: `du -sh ~/.local/share/opencode/snapshot/*/`
  - Expected: lista de snapshots com tamanhos (4111cd0d=76M app_fit, 18685e38=4M opencode_termux, etc.)
  - Run: `rm -rf ~/.local/share/opencode/snapshot/4111cd0d5511f5d54d8b328188f005ae438b7b1a` (exemplo — ajustar conforme decisão)
  - Expected: sem erro; snapshot removido
  - Run: `du -sh ~/.local/share/opencode/snapshot/`
  - Expected: reduzido conforme snapshots deletados
- **Files**: `~/.local/share/opencode/snapshot/`
- **Complexidade**: baixa
- **Nota**: Snapshots são recriados automaticamente quando um projeto é aberto.
  **Decisão do usuário**: confirmar se quer deletar TODOS (incluindo o do projeto
  atual `opencode_termux` e `app_fit`) ou manter o do projeto ativo.

### Task 11: Verificação pós-limpeza (obrigatória)

- **Acceptance**: Given a limpeza concluída, When rodamos os comandos de
  verificação, Then o opencode funciona normalmente e o footprint está reduzido.
- **Verify**:
  - Run: `du -sh ~/.local/share/opencode/ ~/.cache/opencode/`
  - Expected: `~10M` e `~5M` (antes: 3.9G e 12M)
  - Run: `opencode db "SELECT COUNT(*) FROM session; SELECT COUNT(*) FROM event;"`
  - Expected: `0` e `0`
  - Run: `opencode session list`
  - Expected: lista vazia (ou apenas sessões criadas após a limpeza)
  - Run: `opencode stats`
  - Expected: `Sessions 0` (ou valor mínimo) — sem erro
  - Run: `opencode run "teste pós-limpeza" --print-logs 2>&1 | head -5`
  - Expected: opencode responde sem erro (cria nova sessão)
  - Run: `opencode debug paths`
  - Expected: paths intactos (data/cache/config/state)
- **Files**: nenhum (somente leitura)
- **Complexidade**: média

### Checkpoint Final: Todas as tasks concluídas

- Verificar: opencode funcional, DB compactado, footprint reduzido
- Validação: `du -sh ~/.local/share/opencode/` ≤ 20 MB + `opencode run` responde

## Ordem de Implementação

1. Task 1 (pre-flight) → 2. Task 2 (backup) → **Checkpoint 1** →
3. Task 3 (checkpoint WAL) → 4. Task 4 (events) → 5. Task 5 (sessions) →
6. Task 6 (VACUUM) → **Checkpoint 2** →
7. Tasks 7, 8, 9 (paralelas: logs, tool-output, cache) →
8. Task 10 (snapshots, opcional) → 9. Task 11 (verificação) → **Checkpoint Final**

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Perda irreversível de dados (backup falho ou não verificado) | Média | Alto | Task 2 obrigatória com verificação (Checkpoint 1). Se backup falhar, PARAR. Backup via `VACUUM INTO` é consistente por construção. |
| OpenCode rodando durante a limpeza (lock no DB, dados recriados) | Média | Alto | Task 1 verifica `pgrep -f opencode`. Se houver processo, parar antes de Task 3. VACUUM falha com lock — sintoma visível. |
| `VACUUM INTO` não suportado (SQLite antigo no better-sqlite3) | Baixa | Médio | Fallback documentado na Task 2: copiar `db` + `wal` + `shm` com opencode parado. |
| Deleção de arquivos necessários do cache (`bin/rg`, `packages/`) | Baixa | Médio | Whitelist explícita na Task 9: NÃO deletar `bin/` nem `packages/`. |
| Regressão pós-limpeza (opencode quebra ao iniciar) | Baixa | Alto | Task 11 obrigatória: `opencode run` + `opencode stats` + `opencode debug paths`. Restauração via backup da Task 2. |
| Falha de FK ao deletar `event` antes de `event_sequence` | Baixa | Médio | Ordem explícita na Task 4: `event` primeiro, depois `event_sequence`. |

## Verificação Final

- [ ] `du -sh ~/.local/share/opencode/` ≤ 20 MB (era 3.9 GB)
- [ ] `du -sh ~/.cache/opencode/` ≤ 6 MB (era 12 MB)
- [ ] `opencode db "SELECT COUNT(*) FROM session;"` → `0`
- [ ] `opencode db "SELECT COUNT(*) FROM event;"` → `0`
- [ ] `opencode run "teste"` responde sem erro
- [ ] `opencode session list` funciona (lista vazia)
- [x] Backup em `~/opencode-backup-20260916/` existe e é verificável
- [ ] `~/.config/opencode/` intocado (repo versionado intacto)
- [ ] `auth.json` e `account.json` intactos

## Feature List

```json
{
  "features": [
    {
      "id": 1,
      "name": "Pre-flight: medir estado e confirmar opencode parado",
      "status": "done",
      "acceptance": ["du -sh mostra 3.9G/12M", "pgrep não encontra opencode rodando"]
    },
    {
      "id": 2,
      "name": "Backup de segurança via VACUUM INTO",
      "status": "done",
      "acceptance": ["backup de ~3.6 GB criado em ~/opencode-backup-20260916/", "backup contém 1.109 sessões"]
    },
    {
      "id": 3,
      "name": "Checkpoint do WAL (TRUNCATE)",
      "status": "pending",
      "acceptance": ["PRAGMA wal_checkpoint(TRUNCATE) retorna sem erro", "opencode.db-wal reduzido"]
    },
    {
      "id": 4,
      "name": "Deletar eventos de replay (event + event_sequence)",
      "status": "pending",
      "acceptance": ["DELETE FROM event remove 274.866 linhas", "DELETE FROM event_sequence remove 1.109 linhas", "contagens = 0"]
    },
    {
      "id": 5,
      "name": "Deletar todas as sessões (cascade)",
      "status": "pending",
      "acceptance": ["DELETE FROM session remove 1.109 sessões", "message/part/todo = 0"]
    },
    {
      "id": 6,
      "name": "VACUUM para compactar DB",
      "status": "pending",
      "acceptance": ["opencode.db reduzido de 3.6 GB para ~10 MB", "freelist_count = 0"]
    },
    {
      "id": 7,
      "name": "Truncar log (36 MB)",
      "status": "pending",
      "acceptance": ["opencode.log = 0 bytes"]
    },
    {
      "id": 8,
      "name": "Limpar tool-output (1.7 MB)",
      "status": "pending",
      "acceptance": ["tool-output/ vazio"]
    },
    {
      "id": 9,
      "name": "Limpar cache de providers (models.json + tmp)",
      "status": "pending",
      "acceptance": ["models.json e *.tmp removidos", "bin/ e packages/ preservados"]
    },
    {
      "id": 10,
      "name": "Limpar snapshots de git (opcional, até 82 MB)",
      "status": "pending",
      "acceptance": ["snapshots de projetos inativos removidos", "snapshot do projeto ativo preservado (se desejado)"]
    },
    {
      "id": 11,
      "name": "Verificação pós-limpeza",
      "status": "pending",
      "acceptance": ["du -sh ≤ 20 MB", "opencode run responde", "opencode stats sem erro", "config/auth intactos"]
    }
  ]
}
```

## Notas Finais

- **Estimativa de liberação**: ~3.9 GB → ~10-20 MB (99.5%+ de redução).
- **Restauração**: se o usuário mudar de ideia, restaurar com
  `cp ~/opencode-backup-20260916/opencode.db.backup ~/.local/share/opencode/opencode.db`
  (com opencode parado).
- **Este plano NÃO modifica o repo versionado** (`opencode_termux`). Todas as
  operações são em `~/.local/share/opencode/`, `~/.cache/opencode/` e
  `~/.local/state/opencode/` — fora do repo.
- **Execução**: pertence ao `task-build`/`dev`. O `task-planner` apenas planejou.
