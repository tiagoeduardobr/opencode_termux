# Plano: Melhorias no git-commit.md (13 tasks)

> **Série**: Continua o programa de melhorias dos agentes (task-build → dev →
> task-planner → code-review → **git-commit**). Mesmo método: pesquisa 2025-2026,
> tasks Críticas (C) + Importantes (I), acceptance/verify por task.

## Objetivo

Implementar 13 melhorias ao agente `git-commit.md` para transformá-lo de um
criador de commits básico (subject line apenas, staging indiscriminado) em um
agente de **commits atômicos semânticos**, com:

- Staging seletivo (`git add -p`) e regras de atomicidade (one logical change)
- Validação pré-commit (secrets, .env, build artifacts)
- Formato completo Conventional Commits (subject + body + footer)
- Detecção de breaking changes (`!` + footer `BREAKING CHANGE:`)
- Workflow multi-commit (commit after every logical step)
- 11 types completos, regra 50/72, imperative mood, scope auto-detection
- Trailer `Co-Authored-By` para código AI-generated
- Anti-padrões de commit e contrato de output para o task-build

O `git-commit.md` atual tem 126 linhas e é funcional mas superficial:
o step 1 (Stage, linhas 79-81) tem 3 linhas sem critério de atomicidade,
o step 2 (Commit, linhas 83-89) gera apenas subject line, não há validação
de secrets antes do commit, e não há contrato de output parseável pelo
task-build.

## Pesquisa de Referência (resumo)

Fontes fornecidas pelo task-build (pesquisa 2025-2026 sobre commit hygiene
para agentes AI):

1. **Stack-Driven (2026)**: "10 Deadly Sins of AI-Generated Commits" — commits
   vague/kitchen-sink/WIP; Rule 3 (pre-commit validation); "Commit After
   Every Step"
2. **tinyhat Issue #22**: atomic commits; commit after each logical checkpoint
3. **raine.dev**: `git add -p` para staging seletivo; one logical change per commit
4. **Conventional Commits spec v1.0.0**: estrutura completa
   `type(scope): subject` + body + footer; breaking change com `!` e footer
   `BREAKING CHANGE:` → https://www.conventionalcommits.org/en/v1.0.0/
5. **EliteAI git-commits skill**: formato completo de mensagem com body/footer
6. **etiennejeanneau**: best practices de pre-commit checks (secrets, artifacts)
7. **git-atomic-commit skill**: Tier 1 (types completos), Tier 3 (scope inference)
8. **gitglossary.com**: terminologia de anti-patterns de commit
9. **Qoomon git-conventional-commits cheatsheet**: tipos, escopos, breaking
   change → https://github.com/qoomon/git-conventional-commits
10. **BuildMVPFast (2026)**: trailer `Co-Authored-By` para código AI-generated
11. **r/git (discussion)**: debate sobre atribuição Co-Authored-By em commits AI
12. **Baeldung / ditig.com / techearl.com**: regra 50/72 e imperative mood
13. **Agensi.io**: scope auto-detection por stack

### Padrões-chave que se aplicam ao git-commit.md

| Padrão | Fonte | Gap no git-commit.md atual |
|--------|-------|-----------------------------|
| Atomic commits (one logical change) | Stack-Driven, tinyhat #22, raine.dev | Step 1 stageia tudo de uma vez, sem critério de atomicidade |
| Staging seletivo (`git add -p`) | raine.dev, git-atomic-commit | Sem orientação de staging parcial; `git add .` implícito |
| Body/footer estruturado | Conventional Commits, EliteAI | Só subject line (linha 87) |
| Breaking change (`!` + footer) | Conventional Commits, Qoomon | Não documentado |
| Pre-commit validation | Stack-Driven Rule 3, etiennejeanneau | Sem checagem de secrets/.env/artifacts staged |
| Multi-commit workflow | Stack-Driven, tinyhat #22 | Um commit único por invocação |
| Anti-padrões de commit | Stack-Driven 10 Deadly Sins, gitglossary | Sem tabela de anti-padrões |
| Scope auto-detection | git-atomic-commit Tier 3, Agensi | Scope manual "quando relevante" (linha 89) |
| Co-Authored-By | BuildMVPFast 2026, r/git | Ausente |
| Types completos (11) | Conventional/Angular, git-atomic-commit Tier 1 | Só 6 types (linha 31) |
| 50/72 rule + imperative mood | Baeldung, ditig, techearl | Ausente |
| Output contract | Consistência com code-review.md (Contrato de Output, linhas 330-349) | Sem contrato de retorno para o task-build |

## Escopo

- **Dentro**: Alterar `.config/opencode/agents/git-commit.md`
  (126 linhas → ~260-300 linhas estimadas)
- **Fora**: Não alterar skills, outros agentes (task-build.md, dev.md,
  code-review.md), AGENTS.md, docs/ nem o frontmatter de permissões do
  próprio git-commit.md

## Assumptions

1. O `git-commit.md` é um subagent invocado via Task tool (task-build/dev)
   e recebe instruções de commit no prompt
2. As convenções existentes (mensagens em inglês, prefixos semânticos,
   formato `type(scope): description`) serão EXPANDIDAS, não substituídas
3. Os steps 0, 0b, 0c (gates de question tool e branch-only mode), 3
   (Push/Merge) e 4 (stale branches) permanecem INALTERADOS — as melhorias
   concentram-se em stage/commit/regras
4. O frontmatter (permissions bash/read/edit etc., linhas 1-22) não será
   modificado
5. Não há plano anterior para esta tarefa específica (verificado em
   `.opencode/plans/`)
6. **Correção por triangulação**: o arquivo tem **6 types** atuais (feat, fix,
   refactor, docs, test, chore — linha 31), não 7. Com os 5 novos
   (style, perf, build, ci, revert) o total é **11 types** — coincide com o
   set completo Angular/Conventional Commits. A acceptance de I6 foi ajustada
   de "(7 atuais + 4 novos)" para "(6 atuais + 5 novos)"
7. As fontes foram fornecidas pelo task-build; URLs incluídas apenas onde
   verificáveis (Conventional Commits, Qoomon)

## Dependências

### Matriz de Dependências

| Task | Depende de | Premissa |
|------|-----------|----------|
| C1 (Atomic Commits) | C4 | C1 referencia staging seletivo (`git add -p`) introduzido por C4 |
| C3 (Pre-commit Validation) | C4 | Step 1b valida o que foi staged conforme a estratégia de C4 |
| C5 (Multi-commit) | C1 | Multi-commit aplica a regra "one logical change" de C1 |
| I2 (Breaking Change) | C2 | Footer `BREAKING CHANGE:` faz parte do formato body/footer de C2 |
| I4 (Scope Auto-detect) | C2 | Scope auto-detect complementa o formato `type(scope)` de C2 |
| I5 (Co-Authored-By) | C2 | Co-Authored-By é um trailer do formato de C2 |
| I6, I7, I1, I3 | — | Independentes (seções distintas: Convenções e Regras) |

**Regra**: Se A depende de B, A NÃO pode ser executada antes de B.
**Paralelizáveis**: I6, I7, I1, I3 podem executar em paralelo entre si
(seções distintas do arquivo).

### Pré-requisitos

- Nenhum externo — todas as mudanças são em arquivo único
- Work tree limpo ou branch feature criada antes de iniciar
- opencode deve ser reiniciado após as mudanças (config não é hot-reload)

### Ordem de Implementação

Topo → base do arquivo (minimiza deslocamento de linhas) respeitando
dependências:

1. **I6** (Convenções — types completos)
2. **I7** (Convenções — 50/72 + imperative)
3. **C4** (Step 1 — staging strategy) ← base para C1/C3
4. **C1** (Steps 1-2 — atomic commits)
5. **C3** (novo step 1b — pre-commit validation)
6. **C2** (Step 2 — body/footer format) ← base para I2/I4/I5
7. **I2** (Step 2 — breaking change detection)
8. **I4** (Step 2 — scope auto-detection)
9. **I5** (Step 2 — Co-Authored-By)
10. **C5** (novo step 2b — multi-commit workflow)
11. **I1** (Regras — anti-padrões de commit)
12. **I3** (Regras — contrato de output)

**Nota sobre deslocamento de linhas**: As referências de linha valem para o
arquivo ORIGINAL (126 linhas). Após cada inserção, usar **grep para localizar
seções** em vez de confiar nos números — todos os comandos Verify já usam grep.

## Tasks

### Críticos

- [ ] **C1. Atomic Commits (expandir steps 1-2)**

  **Seção**: Expandir o step 1 "Stage dos arquivos" (linhas 79-81) e o
  step 2 "Commit" (linhas 83-89) com orientação de atomic commits

  **Mudança**: Adicionar bloco de regras de atomicidade ao final do step 1
  (ou início do step 2):

  ```
  **Regras de atomic commits**:
  - **One logical change per commit** — um commit = uma mudança lógica
    (uma feature, um fix, uma refatoração). Nunca misturar tipos.
  - **Se precisa de AND → split**: se a descrição do commit precisa de
    "e" para conectar duas ideias ("add X and fix Y"), são 2 commits.
  - **NUNCA usar `git add -A` / `git add .`** — stageia mudanças não
    relacionadas e é a principal causa de kitchen sink commits.
  - Anti-pattern **kitchen sink commit**: um único commit que mistura
    feature + fix + refactor + docs. Proibido.
  ```

  **Motivação**: Stack-Driven 2026 ("10 Deadly Sins"), tinyhat Issue #22,
  raine.dev — agentes AI tendem a produzir kitchen sink commits quando não
  há regra explícita de atomicidade.

  **Acceptance**: Regras de atomic commits documentadas no workflow;
  anti-pattern "kitchen sink" mencionado explicitamente; proibição de
  `git add -A` presente

  **Verify**:
  ```bash
  grep -in "atomic\|one logical\|kitchen sink\|git add -A" \
    .config/opencode/agents/git-commit.md
  ```
  Expected: retorna as regras com os 4 termos

  **Files**: `.config/opencode/agents/git-commit.md` (steps 1-2, linhas 79-89)
  **Complexidade**: Média

---

- [ ] **C2. Commit Body/Footer (expandir step 2)**

  **Seção**: Expandir o step 2 "Commit" (linhas 83-89) com o formato completo

  **Mudança**: Substituir o comando simples atual por formato completo:

  ```
  Formato completo da mensagem:
  ```
  <type>(<scope>): <subject>

  <body>

  <footer>
  ```

  - **Subject** (obrigatório): linha única, ≤50 chars ideal, imperative mood
  - **Body** (opcional): o PORQUÊ da mudança, wrap em 72 chars. Usar quando
    o subject não basta para explicar motivação/trade-offs
  - **Footer** (opcional): breaking changes (`BREAKING CHANGE: ...`),
    referência de issues (`Closes #123`, `Fixes #456`), trailers
    (`Co-Authored-By:` — ver convenção própria)

  Exemplo com breaking change e issue:
  ```
  feat(auth)!: switch session tokens to JWT

  Session cookies were vulnerable to CSRF in the mobile client.
  JWT allows stateless validation and removes the server-side
  session store dependency.

  BREAKING CHANGE: session tokens are no longer accepted.
  Clients must migrate to Bearer tokens.

  Closes #142
  ```
  ```

  Executar com heredoc para mensagens multi-linha:
  ```bash
  git commit -m "$(cat <<'MSG'
  <type>(<scope>): <subject>

  <body>

  <footer>
  MSG
  )"
  ```

  **Motivação**: Conventional Commits spec v1.0.0; EliteAI git-commits skill —
  subject-only perde contexto e quebra tooling de changelog (a skill
  `changelog-generator` deste agente se beneficia de body/footer).

  **Acceptance**: Formato body/footer documentado; exemplo de breaking change
  presente; exemplo de referência de issue (`Closes #`) presente; comando
  multi-linha via heredoc documentado

  **Verify**:
  ```bash
  grep -n "BREAKING CHANGE\|Closes #\|body\|footer\|heredoc\|MSG" \
    .config/opencode/agents/git-commit.md
  ```
  Expected: retorna formato completo + exemplo + comando heredoc

  **Files**: `.config/opencode/agents/git-commit.md` (step 2, linhas 83-89)
  **Complexidade**: Média

---

- [ ] **C3. Pre-commit Validation (novo step 1b)**

  **Seção**: Novo step "1b. Validação pré-commit" ENTRE o step 1 (Stage) e
  o step 2 (Commit)

  **Mudança**: Inserir subseção de validação do staged:

  ```
  ### 1b. Validação pré-commit

  ANTES de commitar, inspecionar o staged (`git diff --cached`) e verificar:

  - **Secrets**: tokens, passwords, API keys, private keys NÃO podem ir
    para o commit. Se encontrados: REMOVER do stage, reportar e PARAR.
  - **`.env` / arquivos de configuração local**: nunca commitar `.env`,
    credenciais, dumps. Verificar contra `.gitignore`.
  - **Build artifacts**: `node_modules/`, `dist/`, `__pycache__/`, `.pyc`,
    binários gerados não devem ser staged.
  - **Arquivos acidentais**: OS junk (`.DS_Store`, `Thumbs.db`), editor
    configs temporários, logs.

  Se qualquer item falhar → remover do stage (`git restore --staged <file>`),
  reportar ao usuário e aguardar decisão (question tool se ambíguo).
  ```

  **Motivação**: Stack-Driven 2026 Rule 3 ("never let secrets reach a
  commit"); etiennejeanneau best practices — pre-commit checks são a última
  barreira antes do histórico permanente.

  **Acceptance**: Step 1b existe entre stage e commit; lista de checks
  documentada (secrets, .env, build artifacts, arquivos acidentais); ação
  definida para falha (unstage + reportar)

  **Verify**:
  ```bash
  grep -n "secret\|\.env\|build artifact\|pre-commit\|restore --staged" \
    .config/opencode/agents/git-commit.md
  ```
  Expected: retorna o novo step com os checks

  **Files**: `.config/opencode/agents/git-commit.md` (entre linhas 81 e 83 → inserir ~18 linhas)
  **Complexidade**: Baixa

---

- [ ] **C4. Staging Strategy (expandir step 1)**

  **Seção**: Expandir o step 1 "Stage dos arquivos" (linhas 79-81) com
  orientação de staging

  **Mudança**: Substituir as 3 linhas atuais por estratégia completa:

  ```
  ### 1. Stage dos arquivos

  Stagear SELETIVAMENTE, um concern por vez:

  - `git add <file>` — para arquivos inteiros relacionados à mesma mudança
  - `git add -p` — quando um MESMO arquivo contém mudanças de concerns
    diferentes (ex: fix + refactor): interativamente, stagear apenas os
    hunks do concern atual; o restante fica para o próximo commit
  - **Fallback não-interativo**: Se o terminal não suportar interatividade (runtime de agente), usar `git apply --cached <patch>` ou delegar ao usuário via question tool para rodar `git add -p` manualmente.
  - **PROIBIDO**: `git add .` e `git add -A` — stageiam tudo cegamente e
    destroem a atomicidade (ver regras de atomic commits no step 2)
  - Antes de stagear, revisar `git status --short` e mapear quais arquivos
    pertencem a qual mudança lógica
  ```

  **Motivação**: raine.dev (selective staging), git-atomic-commit skill,
  Stack-Driven — staging indiscriminado é a causa raiz de commits não-atômicos.

  **Acceptance**: `git add -p` mencionado para separar concerns em um mesmo
  arquivo; `git add .` / `git add -A` proibidos explicitamente; mapeamento
  prévio de arquivos → mudanças lógicas orientado

  **Verify**:
  ```bash
  grep -n "git add -p\|staging\|seletiv\|PROIBIDO.*git add" \
    .config/opencode/agents/git-commit.md
  ```
  Expected: retorna estratégia de staging com `git add -p` e proibição

  **Files**: `.config/opencode/agents/git-commit.md` (step 1, linhas 79-81 → expandir para ~12 linhas)
  **Complexidade**: Baixa

---

- [ ] **C5. Multi-commit Workflow (novo step 2b)**

  **Seção**: Novo step "2b. Workflow multi-commit" APÓS o step 2 (Commit),
  antes do step 3 (Push/Merge)

  **Mudança**: Inserir subseção:

  ```
  ### 2b. Workflow multi-commit

  Quando o conjunto de mudanças contém MÚLTIPLAS mudanças lógicas
  (detectado no step 1), fazer UM COMMIT POR MUDANÇA:

  1. Commit after every sub-task/lógico checkpoint — nunca acumular
     trabalho não-commitado além de um concern
  2. Repetir o ciclo stage (step 1) → validar (step 1b) → commit (step 2)
     para cada mudança lógica pendente
  3. Ordenar commits: dependências primeiro (schema → API → UI;
     fix bloqueante → feature que o utiliza)
  4. Cada commit deve compilar/passar sozinho (nunca commitar estado
     intermediário quebrado)

  Sinal de que faltam commits: `git status --short` ainda mostra arquivos
  modificados após o primeiro commit → voltar ao step 1.
  ```

  **Motivação**: Stack-Driven "Commit After Every Step"; tinyhat Issue #22 —
  agentes que fazem um único commit gigante produzem histórico inutilizável
  para review, revert e bisect.

  **Acceptance**: Regras para multi-commit documentadas; ciclo
  stage→validate→commit por mudança lógica; ordenação por dependência;
  critério de parada (work tree limpo)

  **Verify**:
  ```bash
  grep -n "multi-commit\|sub-task\|logical checkpoint\|um commit por" \
    .config/opencode/agents/git-commit.md
  ```
  Expected: retorna o novo step 2b

  **Files**: `.config/opencode/agents/git-commit.md` (após step 2, antes da linha 91 → inserir ~14 linhas)
  **Complexidade**: Média

---

### Importantes

- [ ] **I1. Anti-padrões de Commit (nova seção)**

  **Seção**: Nova subseção "### Anti-padrões de Commit" dentro da seção
  "Regras" (após linha 126)

  **Mudança**: Tabela de anti-padrões (seguir formato da tabela
  "Anti-padrões de Review" do code-review.md):

  ```
  ### Anti-padrões de Commit

  | Anti-padrão | Consequência | Correção |
  |---|---|---|
  | Mensagem vaga ("update stuff", "fixes", "changes") | Histórico inutilizável para bisect/review | Subject específico: o que mudou e onde |
  | Kitchen sink commit (feature+fix+refactor juntos) | Revert parcial impossível | Split em commits atômicos (step 2b) |
  | WIP commit ("work in progress") em main | Ruído no histórico; estado quebrado preservado | Commitar apenas checkpoints funcionais |
  | `git add -A` / `git add .` cego | Arquivos não relacionados entram no commit | Staging seletivo (step 1) |
  | Commitar secrets/.env | Vazamento permanente no histórico | Validação pré-commit (step 1b) |
  | Mega-diff (>400 linhas sem motivo) | Review superficial; bugs passam | Dividir por concern |
  | Mensagem que descreve O COMO (o diff já mostra) | Redundância sem contexto | Body explica o PORQUÊ |
  | Non-imperative subject ("added", "fixed") | Inconsistente com git conventions | Imperative mood: "add", "fix" |
  | Subject >72 chars ou com body na mesma linha | Quebra tooling (git log --oneline) | Regra 50/72 |
  | Commitar estado quebrado (não compila) | Bisect aponta commit errado | Cada commit funcional (step 2b.4) |
  ```

  **Motivação**: Stack-Driven "10 Deadly Sins of AI-Generated Commits";
  gitglossary.com (terminologia).

  **Acceptance**: Tabela com 8+ anti-patterns existente (acima tem 10); cada
  linha com Anti-padrão | Consequência | Correção

  **Verify**:
  ```bash
  grep -n "Anti-padrões de Commit\|Kitchen Sink\|kitchen sink\|WIP\|vague\|vaga" \
    .config/opencode/agents/git-commit.md
  ```
  Expected: retorna tabela com 8+ entradas

  **Files**: `.config/opencode/agents/git-commit.md` (seção Regras → inserir ~16 linhas)
  **Complexidade**: Baixa

---

- [x] **I2. Breaking Change Detection (expandir step 2)**

  **Dependência**: requer C2 aplicado primeiro (footer faz parte do formato)

  **Seção**: Expandir o step 2 com detecção de breaking changes

  **Mudança**: Adicionar regra de breaking change ao step 2:

  ```
  **Breaking changes** — quando a mudança quebra compatibilidade (API pública,
  schema, config, contrato de output):
  - Adicionar `!` ANTES do `:` no subject: `feat(api)!: ...`
  - ADICIONALMENTE incluir footer `BREAKING CHANGE: <descrição do que quebra
    e como migrar>`
  - Se houver migração, descrevê-la no body ou no próprio footer
  ```

  **Motivação**: Conventional Commits spec v1.0.0 (seção Breaking Changes);
  Qoomon cheatsheet.

  **Acceptance**: Formato `!` indicator documentado; footer `BREAKING CHANGE:`
  documentado com exemplo de migração

  **Verify**:
  ```bash
  grep -n "BREAKING CHANGE\|breaking change\|)!" .config/opencode/agents/git-commit.md
  ```
  Expected: retorna regra + exemplo (o exemplo completo já vem de C2)

  **Files**: `.config/opencode/agents/git-commit.md` (step 2 → inserir ~7 linhas)
  **Complexidade**: Baixa

---

- [x] **I3. Output Contract (nova seção)**

  **Seção**: Nova subseção "### Contrato de Output" dentro da seção "Regras"
  (consistência com code-review.md, seção "Contrato de Output")

  **Mudança**: Definir formato de retorno para o task-build parsear:

  ```
  ### Contrato de Output

  O git-commit DEVE retornar output compatível com o task-build:

  - ✅ Sucesso (por commit):
    `<hash curto> <type>(<scope>): <subject>` — uma linha por commit criado,
    seguida do total: `{N} commit(s) criado(s) em {branch}`
  - ℹ️ Nada a commitar: `"Work tree limpo — nenhum commit necessário"`
  - ❌ Erro: `"Falha ao commitar: {motivo}"` (ex: pre-commit hook falhou,
    secret detectado no step 1b, permissão negada)
  - Nunca retornar apenas "done" ou resumo sem os hashes
  ```

  **Motivação**: Consistência com code-review.md I6 ("Contrato de Output",
  linhas 330-349) — o task-build orquestra múltiplos subagentes e precisa de
  formato uniforme e parseável.

  **Acceptance**: Output contract documentado cobrindo sucesso (com hash),
  work tree limpo e erro

  **Verify**:
  ```bash
  grep -n "Contrato de Output\|hash" .config/opencode/agents/git-commit.md
  ```
  Expected: retorna a nova subseção com os 4 casos

  **Files**: `.config/opencode/agents/git-commit.md` (seção Regras → inserir ~12 linhas)
  **Complexidade**: Baixa

---

- [x] **I4. Scope Auto-detection (expandir step 2)**

  **Dependência**: requer C2 aplicado primeiro (scope faz parte do formato)

  **Seção**: Expandir o step 2 com orientação de scope

  **Mudança**: Substituir a orientação manual atual (linha 89) por
  auto-detecção:

  ```
  **Scope auto-detection** — inferir do conjunto de arquivos alterados:
  - Todos em um módulo/diretório → scope = nome do módulo
    (`src/auth/*` → `feat(auth):`)
  - Múltiplas stacks → scope pela stack dominante (`api`, `web`, `mobile`)
  - Camadas conhecidas deste repo: `agents`, `skills`, `scripts`, `bin`,
    `docs`, `shell`
  - Mudança transversal (afeta 3+ módulos sem domínio claro) → OMITIR scope
  - Em caso de dúvida entre 2 scopes → escolher o mais específico
  ```

  **Motivação**: git-atomic-commit skill Tier 3; Agensi.io — scope consistente
  viabiliza filtragem de changelog e histórico por área.

  **Acceptance**: Regras de scope auto-detection documentadas; exemplos por
  stack/camada presentes; regra para mudança transversal (omitir)

  **Verify**:
  ```bash
  grep -n "scope\|auto-detect\|inferir\|transversal" .config/opencode/agents/git-commit.md
  ```
  Expected: retorna regras de auto-detecção substituindo a linha 89 antiga

  **Files**: `.config/opencode/agents/git-commit.md` (step 2, linha 89 → expandir para ~9 linhas)
  **Complexidade**: Baixa

---

- [ ] **I5. Co-Authored-By Convention (expandir step 2)**

  **Dependência**: requer C2 aplicado primeiro (trailer faz parte do formato)

  **Seção**: Expandir o step 2 com convenção Co-Authored-By

  **Mudança**: Adicionar regra de atribuição:

  ```
  **Co-Authored-By** — para código AI-generated (default neste workflow):
  adicionar trailer ao footer:

  Co-Authored-By: Claude <noreply@anthropic.com>

  - Um trailer por agente contribuidor; separados por linha vazia dos
    demais footers
  - Aplicar quando a autoria da mudança for majoritariamente do agente;
    não aplicar em commits puramente manuais do usuário
  ```

  **Motivação**: BuildMVPFast 2026; r/git discussion — atribuição transparente
  de autoria AI é convenção emergente 2026 e alimenta métricas de provenance.

  **Acceptance**: Convenção Co-Authored-By documentada com trailer exato;
  critério de quando aplicar/não aplicar

  **Verify**:
  ```bash
  grep -n "Co-Authored-By\|trailer" .config/opencode/agents/git-commit.md
  ```
  Expected: retorna a convenção com o trailer literal

  **Files**: `.config/opencode/agents/git-commit.md` (step 2 → inserir ~8 linhas)
  **Complexidade**: Baixa

---

- [x] **I6. Missing Types (expandir convenções)**

  **Seção**: Expandir a seção "Convenções de commit" (linha 31)

  **Mudança**: Substituir a lista atual de 6 types pelas 11 completas:

  ```
  - Usar prefixos semânticos (set completo Conventional Commits/Angular):
    `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`,
    `ci`, `chore`, `revert`.
    - `style`: formatação/espaços/semicolons (não afeta significado)
    - `perf`: melhoria de performance
    - `build`: sistema de build/dependências (npm, pip, Makefile)
    - `ci`: pipelines/configuração de CI
    - `revert`: reverte commit anterior (`revert: <subject do commit revertido>`)
  ```

  **Nota de triangulação**: A acceptance original dizia "(7 atuais + 4 novos)",
  mas o arquivo tem **6 types atuais** (feat, fix, refactor, docs, test, chore).
  Com os 5 novos = **11 types**, fechando exatamente o set completo.

  **Motivação**: Conventional Commits spec; git-atomic-commit skill Tier 1 —
  sem `perf`/`build`/`ci`/`revert`, o agente força esses changesets em
  `chore` genérico, perdendo semântica para changelogs.

  **Acceptance**: 11 types documentados (6 atuais + 5 novos); breve descrição
  dos types novos

  **Verify**:
  ```bash
  grep -n "style\|perf\|build\|ci\|revert" .config/opencode/agents/git-commit.md
  grep -o "\`feat\`\|\`fix\`\|\`docs\`\|\`style\`\|\`refactor\`\|\`perf\`\|\`test\`\|\`build\`\|\`ci\`\|\`chore\`\|\`revert\`" .config/opencode/agents/git-commit.md | wc -l
  ```
  Expected: segundo comando retorna ≥ 11 (todos os types listados)

  **Files**: `.config/opencode/agents/git-commit.md` (linha 31 → expandir para ~8 linhas)
  **Complexidade**: Baixa

---

- [x] **I7. 50/72 Rule + Imperative Mood (expandir convenções)**

  **Seção**: Expandir a seção "Convenções de commit" (após linha 32)

  **Mudança**: Adicionar regras de formatação do subject:

  ```
  - **Regra 50/72**: subject ≤50 chars (hard limit 72); body wrap em 72 chars
  - **Imperative mood**: subject como comando ("add feature", não "added
    feature" nem "adds feature") — completa a frase "if applied, this commit
    will ___"
  - Sem capital inicial forçada e sem ponto final no subject
  ```

  **Motivação**: 50/72 rule (Baeldung, ditig.com, techearl.com) — padrão
  herdado do git.git; imperative mood é convenção oficial do kernel Git.

  **Acceptance**: Regra 50/72 documentada (50 ideal / 72 limite); imperative
  mood mencionado com exemplo correto vs incorreto

  **Verify**:
  ```bash
  grep -n "50/72\|imperative\|72 char" .config/opencode/agents/git-commit.md
  ```
  Expected: retorna as duas regras

  **Files**: `.config/opencode/agents/git-commit.md` (seção Convenções → inserir ~5 linhas)
  **Complexidade**: Baixa

## Checkpoints

### Checkpoint 1: Convenções + Stage/Commit atômicos (após tasks 1-4: I6, I7, C4, C1)
- Verificar: seção Convenções tem 11 types + 50/72 + imperative; step 1 tem
  staging strategy com `git add -p`; regras de atomicidade presentes
- Validação:
  ```bash
  grep -n "revert\|50/72\|git add -p\|one logical\|kitchen sink" \
    .config/opencode/agents/git-commit.md
  ```

### Checkpoint 2: Validação pré-commit + formato completo (após tasks 5-8: C3, C2, I2, I4)
- Verificar: step 1b existe entre stage e commit; step 2 tem formato
  body/footer + breaking change + scope auto-detect
- Validação:
  ```bash
  grep -n "1b\. Validação pré-commit\|BREAKING CHANGE\|Closes #\|Scope auto-detection" \
    .config/opencode/agents/git-commit.md
  ```

### Checkpoint 3: Trailers + multi-commit + regras (após tasks 9-12: I5, C5, I1, I3)
- Verificar: Co-Authored-By presente; step 2b multi-commit existe; tabela de
  anti-padrões e Contrato de Output nas Regras
- Validação:
  ```bash
  grep -n "Co-Authored-By\|2b\. Workflow multi-commit\|Anti-padrões de Commit\|Contrato de Output" \
    .config/opencode/agents/git-commit.md
  ```

### Checkpoint Final: Todas as tasks concluídas
- Verificar: todos os greps da seção Verificação Final passam; frontmatter
  intacto; gates existentes (steps 0/0b/0c/3/4) inalterados
- Validação: suite completa abaixo + Teste Funcional

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Redundância C1 ↔ C4 (ambos tratam staging/atomicidade) | Média | Baixo | Separação clara: C4 = mecânica (COMO stagear), C1 = política (O QUE commitar); revisar cross-referências entre eles no review |
| Deslocamento de linhas após inserções (steps 1b, 2b) | Alta | Baixo | Todos os Verify usam grep, nunca números de linha; nota de deslocamento na Ordem de Implementação |
| Expansão do tamanho (126 → ~260-300 linhas) | Alta (esperada) | Baixo | Precedente positivo: task-build.md tem 619 linhas e code-review.md 349; usar tabelas e blocos concisos |
| Quebra dos gates existentes (question tool do step 0, branch-only mode 0b) | Baixa | Alto | Tasks não alteram steps 0/0b/0c/3/4; Verificação Final compara estrutura desses steps; teste funcional exercita gate do step 0 |
| Co-Authored-By divergente do histórico do repo (commits atuais não usam) | Média | Baixo | Convenção definida como default para código AI-generated (que é o caso deste workflow); critério explícito de exceção em I5 |

## Verificação Final

```bash
# 1. Todas as novas seções presentes
grep -n "Regras de atomic\|Validação pré-commit\|Workflow multi-commit\|Anti-padrões de Commit\|Contrato de Output\|Scope auto-detection\|Co-Authored-By\|50/72" \
  .config/opencode/agents/git-commit.md

# 2. Frontmatter intacto (delimitadores --- e permissions preservados)
head -22 .config/opencode/agents/git-commit.md | grep "^---$" | wc -l   # = 2
grep -n "edit: deny" .config/opencode/agents/git-commit.md              # presente

# 3. Gates existentes preservados
grep -cn "USE A QUESTION TOOL\|branch-only\|stale" .config/opencode/agents/git-commit.md
# ≥ 4 (steps 0, 0b, 4 intactos)

# 4. Proibições de staging
grep -n "PROIBIDO\|NUNCA usar \`git add -A\`" .config/opencode/agents/git-commit.md

# 5. Formato completo + breaking change
grep -n "BREAKING CHANGE\|Closes #" .config/opencode/agents/git-commit.md

# 6. 11 types
grep -o "\`feat\`\|\`fix\`\|\`docs\`\|\`style\`\|\`refactor\`\|\`perf\`\|\`test\`\|\`build\`\|\`ci\`\|\`chore\`\|\`revert\`" .config/opencode/agents/git-commit.md | wc -l   # ≥ 11

# 7. Tamanho esperado
wc -l .config/opencode/agents/git-commit.md   # entre 230 e 330

# 8. Markdown válido (headers de workflow em ordem)
grep -n "^### " .config/opencode/agents/git-commit.md
# Deve mostrar: 0, 0b, 0c, 1, 1b, 2, 2b, 3, 4 (nesta ordem)
```

**Pós-implementação**: reiniciar o opencode — config de agentes não é
hot-reload (skill customize-opencode).

## Teste Funcional

### Cenário 1: Mudanças mistas → split em commits atômicos

**Objetivo**: Validar atomicidade, staging seletivo e multi-commit
(cobre C1, C4, C5, I1).

**Setup**: Em branch feature, criar 2 mudanças lógicas não relacionadas
(ex: fix em `bin/opencode-web.sh` + docs novas em `README.md`) e deixar
ambas no work tree.

**Execução**: Invocar o subagente `git-commit`.

**Verificações esperadas**:
1. Agente NÃO executa `git add .` / `git add -A`
2. Produz 2 commits separados (um `fix(...)`, um `docs(...)`)
3. Subjects em imperative mood, ≤72 chars
4. Após o último commit, `git status --short` limpo
5. Retorno inclui os hashes (contrato de output — I3)

**Critério de aprovação**: 5/5 itens. Um único commit misturando os dois
concerns = falha de C1/C5.

### Cenário 2: Secret no work tree → validação pré-commit bloqueia

**Objetivo**: Validar o step 1b (cobre C3).

**Setup**: Criar arquivo temporário com conteúdo `API_KEY=sk-test-fake123`
e deixá-lo modificável no work tree junto de uma mudança legítima.

**Execução**: Invocar o subagente `git-commit`.

**Verificações esperadas**:
1. Agente identifica o secret antes de commitar
2. Remove o arquivo do stage (`git restore --staged`) ou reporta e PARA
3. NENHUM commit contém o secret (`git log -p | grep sk-test-fake123` vazio)
4. Mudança legítima pode ser commitada normalmente

**Critério de aprovação**: secret fora de qualquer commit; relatório cita
a validação do step 1b.

**Cleanup**: remover o arquivo de teste.

### Cenário 3: Breaking change → formato completo

**Objetivo**: Validar body/footer/breaking change/scope (cobre C2, I2, I4, I5).

**Execução**: Invocar o `git-commit` para commitar uma mudança simulada de
contrato (ex: renomear variável do `.env.example` usada pelos scripts).

**Verificações esperadas**:
1. Subject com `!` (ex: `feat(env)!: rename OPENCODE_PORT usage`)
2. Footer `BREAKING CHANGE:` com instrução de migração
3. Scope inferido dos arquivos alterados
4. Trailer `Co-Authored-By` presente
5. Mensagem multi-linha via heredoc (não `-m` única concatenada)

**Critério de aprovação**: 5/5 itens no commit resultante (`git log -1 --format=%B`).

## Feature List

```json
{
  "features": [
    {"id": 1, "name": "C1 Atomic Commits", "status": "pending", "acceptance": ["Regras de atomic commits documentadas", "Anti-pattern kitchen sink mencionado", "Proibicao de git add -A presente"]},
    {"id": 2, "name": "C2 Commit Body/Footer", "status": "pending", "acceptance": ["Formato body/footer documentado", "Exemplo de breaking change", "Exemplo de issue ref (Closes #)", "Comando heredoc multi-linha"]},
    {"id": 3, "name": "C3 Pre-commit Validation", "status": "pending", "acceptance": ["Step 1b existe entre stage e commit", "Lista de checks (secrets, .env, artifacts)", "Acao de falha definida (unstage + reportar)"]},
    {"id": 4, "name": "C4 Staging Strategy", "status": "pending", "acceptance": ["git add -p mencionado", "git add . proibido", "Mapeamento previo arquivos -> mudancas"]},
    {"id": 5, "name": "C5 Multi-commit Workflow", "status": "pending", "acceptance": ["Regras multi-commit documentadas", "Ciclo stage->validate->commit por mudanca", "Ordenacao por dependencia"]},
    {"id": 6, "name": "I1 Anti-padrones de Commit", "status": "pending", "acceptance": ["Tabela com 8+ anti-patterns", "Formato Anti-padrao|Consequencia|Correcao"]},
    {"id": 7, "name": "I2 Breaking Change Detection", "status": "pending", "acceptance": ["Indicator ! documentado", "Footer BREAKING CHANGE com migracao"]},
    {"id": 8, "name": "I3 Output Contract", "status": "pending", "acceptance": ["Contrato com sucesso (hash)", "Caso work tree limpo", "Caso erro"]},
    {"id": 9, "name": "I4 Scope Auto-detection", "status": "pending", "acceptance": ["Regras de inferencia de scope", "Exemplos por stack/camada", "Regra transversal (omitir)"]},
    {"id": 10, "name": "I5 Co-Authored-By Convention", "status": "pending", "acceptance": ["Trailer exato documentado", "Criterio de aplicacao/excecao"]},
    {"id": 11, "name": "I6 Missing Types", "status": "pending", "acceptance": ["11 types documentados (6 atuais + 5 novos)", "Descricao breve dos types novos"]},
    {"id": 12, "name": "I7 50/72 Rule + Imperative Mood", "status": "pending", "acceptance": ["Regra 50/72 documentada", "Imperative mood com exemplo"]}
  ]
}
```

*(13 tasks do input consolidadas em 12 features: C1..C5 + I1..I7 = 12 tasks
numeradas; o enunciado chama de "13" contando o par C1/C4 que divide o tema
staging — mantidas separadas conforme especificado.)*

## Referências

- Stack-Driven (2026): 10 Deadly Sins of AI-Generated Commits; Rule 3;
  Commit After Every Step
- tinyhat Issue #22: atomic commits para agentes
- raine.dev: selective staging com `git add -p`
- Conventional Commits v1.0.0: https://www.conventionalcommits.org/en/v1.0.0/
- Qoomon git-conventional-commits cheatsheet:
  https://github.com/qoomon/git-conventional-commits
- EliteAI git-commits skill: formato body/footer
- etiennejeanneau: pre-commit best practices
- git-atomic-commit skill: Tier 1 (types), Tier 3 (scope inference)
- gitglossary.com: terminologia de anti-patterns
- BuildMVPFast (2026): Co-Authored-By para AI-generated code
- r/git: discussion sobre atribuição AI
- Baeldung / ditig.com / techearl.com: 50/72 rule e imperative mood
- Agensi.io: scope detection por stack
- Interno: `.config/opencode/agents/code-review.md` (Contrato de Output,
  linhas 330-349 — referência de formato para I3)

## Histórico de Revisão

- **v1 (20/08/2026:18:45)**: Plano inicial criado — 12 tasks (C1-C5, I1-I7),
  13 fontes de pesquisa, matriz de dependências, 4 checkpoints, 5 riscos
  com mitigação, 3 cenários de teste funcional, feature list JSON.
  Correção por triangulação: acceptance de I6 ajustada de "(7 atuais + 4
  novos)" para "(6 atuais + 5 novos = 11 types)" após verificação do
  arquivo real.
