# Plano: Consistência na Documentação do opencode_termux

> **Data**: 28/08/2026 (refinado 28/08/2026 10:45)
> **Tipo**: Documentação (7 aspectos: contagem de skills, links, terminologia, estado real vs documentado, diagramas, tabelas, linter, consolidação de planos)
> **Base**: Análise do estado real do repo (skills, agents, scripts, planos, versões)

## Objetivo

Reconciliar a documentação do `opencode_termux` com o estado real do repositório,
eliminando divergências de contagem de skills, links quebrados, terminologia
inconsistente, versões desatualizadas, diagramas e tabelas desatualizados, e
consolidando os 16 planos antigos em `.opencode/plans/`. Adicionar linter de
markdown para prevenir regressões futuras.

## Escopo

- **Dentro**:
  - `AGENTS.md`, `README.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`,
    `docs/SESSION_CONTEXT_20260618.md`, `docs/AGENTS_TEMPLATE.md`, `AI_HANDOVER.md`
  - `.config/opencode/skills/` (somente leitura — inventário canônico)
  - `.opencode/plans/` (16 planos — consolidação)
  - Novo: `.markdownlint-cli2.jsonc`, `package.json` (raiz, devDependency linter)
  - `opencode.json` (se necessário, para refletir inventário canônico)
- **Fora**:
  - Mudanças em agentes `.md` (`.config/opencode/agents/`) — prompts, não docs
  - Mudanças em skills (conteúdo dos SKILL.md)
  - Scripts `bin/`, `scripts/`, `shell/` (comportamento, não docs)
  - Execução do upgrade OpenCode 1.18.23 (plano `20260827_2301` em andamento —
    este plano apenas reconcilia as docs com o estado real, não executa o upgrade)
  - PRs (projeto usa merge direto fast-forward)

## Assumptions

1. **Contagem real de skills = 50** (verificado: `ls -d .config/opencode/skills/*/ | wc -l` = 50).
2. **Breakdown canônico a ser confirmado na Task 1** — duas classificações candidatas:
   - **A** (base SESSION_CONTEXT, tabela por skill): 27 globais + 11 obra/superpowers + 10 upstream + 2 unificadas = 50
   - **B** (base MULTI_AGENT_ORCHESTRATION, lista de 14 obra): 24 globais + 14 obra/superpowers + 10 upstream + 2 unificadas = 50
   - A Task 1 verifica a origem real de cada skill e escolhe UMA; o requisito
     inegociável é: **a soma do breakdown deve ser exatamente 50** e idêntica em todos os docs.
3. **Versão real do OpenCode**: CLI `1.18.23` (verificado neste ambiente) e plugin
   `^1.18.25` (worktree, decisão do usuário registrada no plano `20260827_2301`,
   linhas 98–101). As docs ainda referenciam `1.18.21` como vigente — desatualizadas.
4. **Upgrade 1.18.23 em andamento**: branch `feature/upgrade-opencode-1-18-23`
   com `package.json`/`package-lock.json` modificados (não commitados) e 9 planos
   untracked. A Task 5 (versões) deve verificar o estado real NO MOMENTO da
   implementação — se o upgrade for mergeado antes, usar a versão final.
5. **Planos**: dos 16 planos, 14 estão concluídos (commits existem), 1 duplicado
   (`20260819_1425` vs `20260819_1446` — mesmo plano de melhorias do dev, 1 linha
   de diferença), 1 em andamento (`20260827_2301` — upgrade 1.18.23).
6. **Linter**: não existe config de markdownlint no repo (verificado).
7. **Badge LICENSE no README (linha 4)**: aponta para arquivo `LICENSE` inexistente.
   **Decisão do usuário**: REMOVER o badge inteiro (não criar `LICENSE`, não corrigir link).
8. **README não possui diagramas mermaid** — usa diagramas ASCII. O ÚNICO diagrama
   mermaid do repo está em `docs/MULTI_AGENT_ORCHESTRATION.md` (linhas 173–199).
   Ambos (mermaid + ASCII) devem refletir o estado real.
9. **Diagramas desatualizados confirmados**:
   - `docs/MULTI_AGENT_ORCHESTRATION.md` mermaid (linhas 173–199): mostra
     `D2[plan-reviewer]` e `D3[code-review]` como passos separados; o workflow real
     (task-build.md step 4b) delega a revisão do plano ao `code-review`, que carrega
     a skill `plan-reviewer`. Diagrama desatualizado.
   - `README.md` diagrama de estrutura (linhas 21–58): omite `run-opencode-tailscale.sh`,
     `bin/opencode-tailscale.sh`, `bin/opencode-tailscale-stop.sh`, `docs/tailscale/`,
     `docs/decisions/`, `docs/AGENTS_TEMPLATE.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`,
     `docs/SESSION_CONTEXT_20260618.md`, `AI_HANDOVER.md`.
   - `README.md` diagrama de arquitetura (linhas 350–378): mostra
     `termux-notification (fallback local)` — recurso REMOVIDO (gotcha AGENTS.md:
     `termux-notification-remove` removido por bug MIUI).
10. **Tabelas desatualizadas confirmadas**:
    - `README.md` tabela "Fluxo" (linhas 382–390): passo 6 menciona
      `tenta termux-notification` — desatualizado (recurso removido).
    - `README.md` linha 462 (`shell/aliases.sh`): lista apenas 4 aliases
      (`opencode_web`, `opencode_web_stop`, `termux_ssh`, `termux_ssh_stop`), mas o
      arquivo real define 6 (faltam `opencode_tailscale`, `opencode_tailscale_stop`).
    - `README.md` linhas 25 e 404: breakdown de skills desatualizado
      ("8 novas upstream" → 10; soma inconsistente).
    - `docs/SESSION_CONTEXT_20260618.md` tabela de skills (linhas 79–129): 49 skills,
      falta `code-architecture-tailwind-v4-best-practices` (coberto pela Task 2).
11. Branch de trabalho: `feature/docs-consistency` criada a partir de `main`
    (delegada ao `git-commit`). Nenhuma task executa em `main` diretamente.

## Dependências

### Matriz de Dependências

| Task | Depende de | Premissa |
|------|-----------|----------|
| Task 1 (inventário skills) | — | Read-only; produz breakdown canônico |
| Task 2 (contagem nos docs) | Task 1 | Breakdown canônico precisa existir antes de editar docs |
| Task 3 (links) | — | Independente; edita docs (sequencial com 2/4/5/6/7 p/ evitar conflito) |
| Task 4 (terminologia) | — | Independente; edita docs (sequencial com 2/3/5/6/7) |
| Task 5 (versões) | — | Independente; edita docs (sequencial com 2/3/4/6/7); verifica estado real antes |
| Task 6 (diagramas) | — | Independente; edita README + MULTI_AGENT_ORCHESTRATION (sequencial com 2–5/7) |
| Task 7 (tabelas) | — | Independente; edita README + docs (sequencial com 2–6) |
| Task 8 (linter) | Tasks 2–7 | Linter roda sobre docs já corrigidas (evita violações em texto que será editado) |
| Task 9 (planos) | — | Independente (arquivos diferentes); pode ser paralela a 2–8 |
| Task 10 (verificação final) | Todas | Coerência final depende de todas as edits |

**Regra**: Tasks 2–7 editam os MESMOS arquivos (AGENTS.md, README.md, docs/*) →
devem ser executadas em sequência (não paralelas) para evitar conflito de merge.
Task 9 é independente (edita apenas `.opencode/plans/`) → pode ser paralela.

### Pré-requisitos

- Branch `feature/docs-consistency` criada a partir de `main` (via `git-commit`).
- Estado real verificado: `opencode --version`, `cat .config/opencode/package.json`,
  `ls -d .config/opencode/skills/*/ | wc -l`.

## Ordem de Implementação

1. Task 1 (inventário canônico) → **Checkpoint 1**
2. Task 2 (contagem) → Task 3 (links) → Task 4 (terminologia) → Task 5 (versões)
   → Task 6 (diagramas) → Task 7 (tabelas) — sequenciais, nesta ordem → **Checkpoint 2**
3. Task 8 (linter) e Task 9 (planos) — podem ser paralelas entre si → **Checkpoint 3**
4. Task 10 (verificação final) → **Checkpoint Final**

## Tasks

### Task 1: Estabelecer inventário canônico de skills (read-only)

- **Acceptance**: Given 50 diretórios em `.config/opencode/skills/`, When a origem
  de cada skill é verificada contra fontes autoritativas (repo obra/superpowers,
  ADR-008 para upstream, histórico de unificação para design-system/frontend-complete),
  Then um breakdown canônico é produzido com soma exatamente 50 e cada skill
  classificada em exatamente uma categoria (global / obra-superpowers / upstream / unificada).
- **Verify**:
  ```bash
  ls -d .config/opencode/skills/*/ | wc -l          # 50
  # Breakdown canônico documentado (ex: 27+11+10+2 ou 24+14+10+2) — soma = 50
  ```
- **Files**: nenhum (read-only; output alimenta Task 2)
- **Complexidade**: média
- **Notas**:
  - Fontes autoritativas: lista canônica do repo `obra/superpowers` (14 skills:
    brainstorming, dispatching-parallel-agents, executing-plans,
    finishing-a-development-branch, receiving-code-review, requesting-code-review,
    subagent-driven-development, systematic-debugging, test-driven-development,
    using-git-worktrees, using-superpowers, verification-before-completion,
    writing-plans, writing-skills); ADR-008 (10 upstream); SESSION_CONTEXT tabela
    (49 skills, falta `code-architecture-tailwind-v4-best-practices`).
  - Divergência conhecida: SESSION_CONTEXT classifica `agent-restrictions` e
    `plan-reviewer` como obra (11 total); MULTI_AGENT_ORCHESTRATION classifica
    brainstorming/executing-plans/systematic-debugging/using-superpowers/
    verification-before-completion como obra (14 total). Resolver com verificação
    real (conteúdo do SKILL.md, git log de adição) e documentar a decisão.

### Checkpoint 1: Inventário canônico estabelecido

- Verificar: breakdown soma 50; cada skill tem origem única
- Validação: tabela de 50 entradas revisada antes de editar docs

### Task 2: Corrigir contagem/breakdown de skills nos 5 docs ✅

- **Acceptance**: Given o breakdown canônico da Task 1, When todas as referências
  de contagem são atualizadas, Then toda menção a "N skills" nos docs usa o total
  50 com breakdown que soma 50, sem variações divergentes.
- **Verify**:
  ```bash
  grep -rn "skills" AGENTS.md README.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md docs/AGENTS_TEMPLATE.md | grep -E "[0-9]+ skills|[0-9]+ globais|[0-9]+ obra|[0-9]+ upstream"
  # Todas as linhas devem refletir o breakdown canônico (soma 50)
  ```
- **Files**: `AGENTS.md` (linhas 12, 131), `README.md` (linhas 25, 355, 404),
  `docs/MULTI_AGENT_ORCHESTRATION.md` (linhas 4, 226, 235, 293, 314, 690),
  `docs/SESSION_CONTEXT_20260618.md` (linhas 34, 77, 228, 234, 244),
  `docs/AGENTS_TEMPLATE.md` (linha 37)
- **Complexidade**: média
- **Notas**:
  - AGENTS.md linha 12: "50 skills (27 globais + 14 do obra/superpowers + 10 novas upstream)" — soma 51, corrigir.
  - README.md linha 25/404: "27 + 14 + 8 novas upstream + plan-reviewer" — 8 upstream errado (ADR-008 confirma 10), corrigir.
  - SESSION_CONTEXT linha 34: "25 globais" mas tabela tem 26 globais; tabela (49) falta `code-architecture-tailwind-v4-best-practices`.
  - AGENTS_TEMPLATE linha 37: "49 skills" → 50.

### Task 3: Verificar e corrigir links internos (REMOVER badge LICENSE) ✅

- **Acceptance**: Given todos os arquivos `.md` do repo, When um script de
  verificação de links internos roda (arquivos relativos + âncoras de seção),
  Then nenhum link interno quebrado permanece (arquivo destino existe; âncora
  de seção válida quando referenciada). O badge `LICENSE` do README é REMOVIDO
  por completo (linha 4), não apenas corrigido.
- **Verify**:
  ```bash
  # Script de verificação (bash/python) que extrai links relativos de *.md
  # e confirma existência do destino; saída vazia = OK
  grep -n "License-MIT\|LICENSE" README.md   # NENHUMA linha (badge removido)
  ```
- **Files**: todos os `.md` afetados (confirmado: `README.md` badge `LICENSE` linha 4)
- **Complexidade**: média
- **Notas**:
  - **Badge LICENSE (README.md linha 4)**: `[![License: MIT](...)](LICENSE)` — arquivo
    `LICENSE` não existe. **Decisão do usuário: REMOVER o badge inteiro** (linha 4),
    NÃO criar `LICENSE` e NÃO corrigir o link. O badge é removido por completo.
  - Verificar também: referências a seções (`#seção`) nos 4 docs principais e
    referências a arquivos em `docs/decisions/` (ADR-001..009 existem).

### Task 4: Padronizar terminologia

- **Acceptance**: Given um glossário de termos definido (abaixo), When os termos
  são aplicados nos 5 docs, Then o uso é consistente (grep não encontra variações
  divergentes dos termos canônicos).
- **Verify**:
  ```bash
  grep -rniE "superpowers|upstream|globais|subagentes|agentes" AGENTS.md README.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md docs/AGENTS_TEMPLATE.md
  # Uso consistente com o glossário
  ```
- **Files**: `AGENTS.md`, `README.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`,
  `docs/SESSION_CONTEXT_20260618.md`, `docs/AGENTS_TEMPLATE.md`
- **Complexidade**: média
- **Glossário proposto** (validar na implementação):
  | Termo canônico | Variações a eliminar |
  |---|---|
  | `obra/superpowers` | `superpowers` solto, `obra` solto |
  | `upstream` | `novas upstream`, `skills upstream` (manter "skills upstream" como frase, padronizar) |
  | `globais` | `global` (quando substantivo plural) |
  | `subagentes` | `subagents` (PT-BR é o idioma dos docs) |
  | `agentes` | `agents` (PT-BR) |
  | `skills` | `skills` (manter em inglês — termo técnico do OpenCode) |
  | `unificadas` | `unificada` (quando plural) |

### Task 5: Reconciliar versões OpenCode (estado real vs documentado)

- **Acceptance**: Given CLI `1.18.23` e plugin `^1.18.25` (estado real verificado
  no momento da implementação), When as referências de versão são atualizadas,
  Then nenhuma referência a `1.18.21` permanece como versão vigente; `1.18.23`
  (CLI) e `1.18.25` (plugin) aparecem consistentemente; `AI_HANDOVER.md` não
  referencia `1.18.18` como versão atual.
- **Verify**:
  ```bash
  opencode --version                                   # 1.18.23 (ou versão real)
  grep -n "1.18.23\|1.18.25" AGENTS.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md AI_HANDOVER.md
  grep -rn "1\.18\.21" AGENTS.md docs/ | grep -v "SESSION_CONTEXT" || echo "OK: sem refs vigentes a 1.18.21"
  ```
- **Files**: `AGENTS.md` (Melhorias Recentes — adicionar entrada 1.18.23/1.18.25),
  `docs/MULTI_AGENT_ORCHESTRATION.md` (cabeçalho linha 4),
  `docs/SESSION_CONTEXT_20260618.md` (nova seção "Atualização OpenCode 1.18.23"),
  `AI_HANDOVER.md` (versão atual + histórico)
- **Complexidade**: média
- **Notas**:
  - **Coordenação com upgrade em andamento**: o plano `20260827_2301` (upgrade
    1.18.23) já tem Tasks 3–5 de docs. Esta Task 5 absorve/substitui essas edits
    (mesmo resultado). Se o upgrade for mergeado antes desta task, apenas verificar
    e ajustar o que faltar (ex: AI_HANDOVER, que o upgrade excluiu do escopo).
  - `AI_HANDOVER.md` linha 18 diz "OpenCode versão: 1.18.18" — desatualizado.
  - Plugin `^1.18.25` é decisão do usuário (caret resolve para 1.18.25) — documentar
    como nota, não como erro.

### Task 6: Atualizar diagramas desatualizados (mermaid + ASCII)

- **Acceptance**: Given os diagramas do repo (1 mermaid em
  `docs/MULTI_AGENT_ORCHESTRATION.md` + diagramas ASCII no `README.md`), When
  atualizados para refletir o estado real, Then cada diagrama representa
  fielmente o fluxo/estrutura atual (agentes, skills, scripts, arquitetura),
  sem elementos removidos ou omitidos.
- **Verify**:
  ```bash
  # 1. Mermaid MULTI_AGENT_ORCHESTRATION: revisão visual do fluxo (D2/D3 corrigidos)
  # 2. README estrutura: conferir que a árvore lista todos os arquivos reais
  #    (run-opencode-tailscale.sh, bin/opencode-tailscale*.sh, docs/tailscale/,
  #     docs/decisions/, AI_HANDOVER.md, docs/MULTI_AGENT_ORCHESTRATION.md, etc.)
  # 3. README arquitetura: conferir que NÃO menciona termux-notification (fallback local)
  grep -n "termux-notification (fallback local)" README.md   # NENHUMA linha
  grep -n "plan-reviewer: revisar plano" docs/MULTI_AGENT_ORCHESTRATION.md  # corrigido p/ code-review
  ```
- **Files**: `README.md` (diagramas ASCII: estrutura linhas 21–58, arquitetura
  linhas 350–378), `docs/MULTI_AGENT_ORCHESTRATION.md` (mermaid linhas 173–199)
- **Complexidade**: média
- **Notas**:
  - **Mermaid em MULTI_AGENT_ORCHESTRATION (linhas 173–199)**: o fluxo mostra
    `D2[plan-reviewer: revisar plano]` e `D3[code-review: revisar plano]` como dois
    passos separados. O workflow real (task-build.md step 4b) delega a revisão do
    plano ao `code-review`, que carrega a skill `plan-reviewer`. Corrigir o diagrama
    para refletir: `D[task-planner] → D2[code-review: revisar plano (carrega plan-reviewer)]`.
  - **README estrutura (linhas 21–58)**: adicionar arquivos omitidos:
    `run-opencode-tailscale.sh`, `bin/opencode-tailscale.sh`, `bin/opencode-tailscale-stop.sh`,
    `docs/tailscale/`, `docs/decisions/`, `docs/AGENTS_TEMPLATE.md`,
    `docs/MULTI_AGENT_ORCHESTRATION.md`, `docs/SESSION_CONTEXT_20260618.md`, `AI_HANDOVER.md`.
  - **README arquitetura (linhas 350–378)**: remover `termux-notification (fallback local)`
    — recurso removido (gotcha AGENTS.md: `termux-notification-remove` removido por bug MIUI).
    O fluxo real usa apenas ntfy.sh push.

### Task 7: Atualizar tabelas desatualizadas ✅

- **Acceptance**: Given as tabelas dos docs, When comparadas com o estado real
  (scripts, aliases, skills, fluxo), Then nenhuma tabela contém informação
  desatualizada ou omitida (aliases completos, fluxo sem termux-notification,
  breakdown de skills correto).
- **Verify**:
  ```bash
  # 1. README aliases (linha 462): conferir que lista os 6 aliases reais
  grep -n "opencode_tailscale\|opencode_tailscale_stop" README.md   # presentes
  # 2. README Fluxo (linhas 382-390): passo 6 sem "tenta termux-notification"
  grep -n "tenta termux-notification" README.md   # NENHUMA linha
  # 3. README skills (linhas 25, 404): breakdown soma 50 (coberto pela Task 2)
  ```
- **Files**: `README.md` (tabela Fluxo linhas 382–390, aliases linha 462),
  `docs/SESSION_CONTEXT_20260618.md` (tabela de skills — coberto pela Task 2),
  outros docs conforme verificação
- **Complexidade**: média
- **Notas**:
  - **README aliases (linha 462)**: `shell/aliases.sh` define 6 aliases
    (`opencode_web`, `opencode_web_stop`, `opencode_tailscale`, `opencode_tailscale_stop`,
    `termux_ssh`, `termux_ssh_stop`). A doc lista apenas 4 — adicionar os 2 de Tailscale.
  - **README Fluxo (linhas 382–390)**: passo 6 diz "tenta `termux-notification`" —
    recurso removido. Atualizar para refletir apenas ntfy.sh push.
  - **README skills (linhas 25, 404)**: breakdown desatualizado — corrigido na Task 2;
    esta task garante que as tabelas de skills refletem o breakdown canônico.
  - **SESSION_CONTEXT tabela de skills (linhas 79–129)**: 49 skills, falta
    `code-architecture-tailwind-v4-best-practices` — coberto pela Task 2.

### Task 8: Adicionar markdownlint ✅

- **Acceptance**: Given config de markdownlint commitado, When
  `npx markdownlint-cli2 "**/*.md"` roda na raiz, Then 0 erros (ou exceções
  explicitamente configuradas no config, com justificativa).
- **Verify**:
  ```bash
  npx markdownlint-cli2 "**/*.md"   # exit 0
  ```
- **Files**: `.markdownlint-cli2.jsonc` (novo), `package.json` (novo, raiz —
  devDependency `markdownlint-cli2` + script `lint:docs`), docs corrigidos
- **Complexidade**: média
- **Notas**:
  - Escolha: `markdownlint-cli2` (moderno, globs nativos, config JSONC).
  - Config inicial sugerida: `MD013` (line length) desabilitado ou `line_length: 0`
    (docs têm linhas longas intencionais); `MD024` (duplicate headings) avaliar;
    `MD033` (inline HTML) permitir se necessário (badges/HTML nos docs).
  - Rodar `--fix` para violações automáticas; revisar manualmente as demais.
  - Não adicionar ao `.config/opencode/package.json` (mistura deps de skills com
    dev tooling) — usar `package.json` na raiz.

### Task 9: Consolidar planos antigos

- **Acceptance**: Given 16 planos em `.opencode/plans/`, When consolidados, Then
  `.opencode/plans/` contém apenas planos ativos + `README.md` (índice);
  `.opencode/plans/archive/` contém os concluídos; nenhum duplicado permanece.
- **Verify**:
  ```bash
  ls .opencode/plans/                          # ativos + README.md + archive/
  ls .opencode/plans/archive/ | wc -l          # 14 (concluídos)
  ls .opencode/plans/*.md | wc -l              # 2 (ativo + README) ou 1+README
  git status --short .opencode/plans/          # renames via git mv (histórico preservado)
  ```
- **Files**: `.opencode/plans/*.md` (16 arquivos)
- **Complexidade**: média
- **Notas**:
  - **Duplicado**: `20260819_1425_melhorias-dev.md` e `20260819_1446_melhorias-dev.md`
    (528 linhas cada, 1 linha difere: "agentes de implementação" vs "coding agents").
    Manter `1446` (versão posterior), arquivar `1425`.
  - **Em andamento (NÃO arquivar)**: `20260827_2301_upgrade-opencode-1-18-23.md`.
  - **Concluídos (arquivar)**: os outros 14 (commits correspondentes existem:
    `dc4f00a`, `58fc4ea`, `609d579`, `68e2b11`, `825294a`, `5a1bf2b`, `6cc03d2`,
    `d04a640`, etc.).
  - Usar `git mv` (preserva histórico). Criar `README.md` índice com tabela:
    plano → status → commit de referência.

### Checkpoint 2: Docs reconciliadas

- Verificar: contagem 50 consistente; links OK (badge LICENSE removido); terminologia
  uniforme; versões reais; diagramas atualizados; tabelas atualizadas
- Validação: greps das Tasks 2–7 verdes

### Checkpoint 3: Linter + planos

- Verificar: markdownlint passa; planos consolidados
- Validação: `npx markdownlint-cli2 "**/*.md"` exit 0; `ls .opencode/plans/` correto

### Task 10: Verificação final consolidada

- **Acceptance**: Given todas as tasks anteriores concluídas, When a verificação
  final roda, Then todos os checks passam simultaneamente.
- **Verify**:
  ```bash
  ls -d .config/opencode/skills/*/ | wc -l                          # 50
  grep -rn "50 skills" AGENTS.md README.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md docs/AGENTS_TEMPLATE.md
  grep -n "License-MIT\|LICENSE" README.md                          # NENHUMA (badge removido)
  grep -n "termux-notification (fallback local)" README.md          # NENHUMA
  grep -n "tenta termux-notification" README.md                     # NENHUMA
  npx markdownlint-cli2 "**/*.md"                                   # exit 0
  opencode --version                                                # versão real
  git diff --stat                                                   # arquivos esperados
  ```
- **Files**: nenhum (read-only)
- **Complexidade**: baixa

### Checkpoint Final: Todas as tasks concluídas

- Verificar: todos os checks da Task 10 verdes
- Validação: code review OBRIGATÓRIO do diff (via task-build) antes do commit

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Classificação de origem das skills ambígua (docs divergem: 11 vs 14 obra) | Alta | Médio | Task 1 verifica contra fontes autoritativas (repo obra/superpowers, ADR-008, git log); requisito inegociável: breakdown soma 50 e é idêntico em todos os docs |
| Conflito com upgrade 1.18.23 em andamento (branch com package.json/lock não commitados; docs de versão sendo editadas pelo plano `20260827_2301`) | Média | Alto | Task 5 verifica estado real NO MOMENTO da implementação; absorve as edits de docs do plano de upgrade; se upgrade mergeado antes, ajustar apenas o que faltar (ex: AI_HANDOVER) |
| Diagramas (mermaid + ASCII) divergem do fluxo real após edição (ex: mermaid mostra plan-reviewer como passo separado) | Média | Médio | Task 6 verifica contra task-build.md (workflow real) e AGENTS.md (gotchas); revisão visual do diagrama após edição |
| Remoção do badge LICENSE deixa referência residual (ex: menção a "MIT" em outro lugar do README) | Baixa | Baixo | Task 3 + Task 10 fazem grep de `LICENSE`/`License-MIT` no README; revisão do diff |
| markdownlint gera muitas violações em docs existentes (linhas longas, HTML inline, headings duplicados) | Média | Médio | Config inicial tolerante (MD013 off, MD033 avaliar); `--fix` para automáticas; exceções documentadas no config com justificativa |
| Movimentação de planos quebra referências externas (ex: docs que citam `.opencode/plans/...`) | Baixa | Baixo | Usar `git mv` (preserva histórico); README índice documenta onde cada plano foi parar; grep de referências antes de mover |
| Regressão de conteúdo durante edição massiva de docs (Tasks 2–7 tocam os mesmos 5 arquivos) | Baixa | Alto | Tasks 2–7 sequenciais (não paralelas); code review obrigatório do diff; `git diff` revisado antes do commit |

## Feature List

```json
{
  "features": [
    {
      "id": 1,
      "name": "Inventário canônico de skills (50, com origens)",
      "status": "pending",
      "acceptance": ["Given 50 dirs em .config/opencode/skills/, When origens verificadas contra fontes autoritativas, Then breakdown soma exatamente 50 com origem única por skill"]
    },
    {
      "id": 2,
      "name": "Contagem de skills corrigida nos 5 docs",
      "status": "pending",
      "acceptance": ["Given breakdown canônico, When referências atualizadas, Then toda menção a N skills usa 50 com breakdown que soma 50"]
    },
    {
      "id": 3,
      "name": "Links internos verificados e corrigidos (badge LICENSE REMOVIDO)",
      "status": "pending",
      "acceptance": ["Given todos os .md, When script de verificação roda, Then nenhum link interno quebrado; badge LICENSE do README removido por completo"]
    },
    {
      "id": 4,
      "name": "Terminologia padronizada nos 5 docs",
      "status": "pending",
      "acceptance": ["Given glossário definido, When termos aplicados, Then grep não encontra variações divergentes"]
    },
    {
      "id": 5,
      "name": "Versões OpenCode reconciliadas (1.18.23 CLI / 1.18.25 plugin)",
      "status": "pending",
      "acceptance": ["Given estado real verificado, When docs atualizadas, Then nenhuma ref a 1.18.21 como vigente; AI_HANDOVER sem 1.18.18 como atual"]
    },
    {
      "id": 6,
      "name": "Diagramas atualizados (mermaid MULTI_AGENT_ORCHESTRATION + ASCII README)",
      "status": "done",
      "acceptance": ["Given diagramas do repo, When atualizados, Then refletem o estado real (fluxo code-review/plan-reviewer, estrutura completa, sem termux-notification fallback)"]
    },
    {
      "id": 7,
      "name": "Tabelas desatualizadas atualizadas (aliases, fluxo, skills)",
      "status": "pending",
      "acceptance": ["Given tabelas dos docs, When comparadas com estado real, Then nenhuma tabela contém info desatualizada (6 aliases, fluxo sem termux-notification, breakdown 50)"]
    },
    {
      "id": 8,
      "name": "markdownlint configurado e passando",
      "status": "pending",
      "acceptance": ["Given config commitado, When npx markdownlint-cli2 roda, Then exit 0 (ou exceções documentadas)"]
    },
    {
      "id": 9,
      "name": "Planos consolidados (16 → ativos + archive + README)",
      "status": "pending",
      "acceptance": ["Given 16 planos, When consolidados via git mv, Then raiz tem só ativos + README; archive tem 14; duplicado dev resolvido"]
    },
    {
      "id": 10,
      "name": "Verificação final consolidada",
      "status": "pending",
      "acceptance": ["Given todas as tasks concluídas, When verificação final roda, Then todos os checks passam"]
    }
  ]
}
```

## Verificação Final

```bash
# 1. Contagem de skills
ls -d .config/opencode/skills/*/ | wc -l                          # 50

# 2. Breakdown consistente (soma 50 em todos os docs)
grep -rn "skills" AGENTS.md README.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md docs/AGENTS_TEMPLATE.md | grep -E "[0-9]+ skills|[0-9]+ globais|[0-9]+ obra|[0-9]+ upstream"

# 3. Links internos (script de verificação — saída vazia) + badge LICENSE removido
grep -n "License-MIT\|LICENSE" README.md                          # NENHUMA linha

# 4. Terminologia (grep do glossário — sem variações divergentes)

# 5. Versões
opencode --version                                                # 1.18.23 (ou real)
grep -n "1.18.23\|1.18.25" AGENTS.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md AI_HANDOVER.md

# 6. Diagramas atualizados
grep -n "termux-notification (fallback local)" README.md          # NENHUMA
grep -n "plan-reviewer: revisar plano" docs/MULTI_AGENT_ORCHESTRATION.md  # corrigido p/ code-review

# 7. Tabelas atualizadas
grep -n "opencode_tailscale\|opencode_tailscale_stop" README.md   # presentes (6 aliases)
grep -n "tenta termux-notification" README.md                     # NENHUMA

# 8. Linter
npx markdownlint-cli2 "**/*.md"                                   # exit 0

# 9. Planos
ls .opencode/plans/                                               # ativos + README + archive/
ls .opencode/plans/archive/ | wc -l                               # 14

# 10. Diff limpo
git diff --stat                                                   # apenas arquivos esperados
```

Critérios de sucesso:
1. Contagem de skills = 50 com breakdown que soma 50, idêntico em todos os docs
2. Nenhum link interno quebrado; badge LICENSE removido do README
3. Terminologia uniforme (glossário aplicado)
4. Docs refletem estado real (versões, agentes, scripts)
5. Diagramas (mermaid + ASCII) refletem o estado real (fluxo, estrutura, arquitetura)
6. Tabelas atualizadas (aliases completos, fluxo sem termux-notification, breakdown 50)
7. markdownlint configurado e passando (prevenção de regressão)
8. Planos consolidados (sem duplicados; ativos na raiz; concluídos em archive/)
