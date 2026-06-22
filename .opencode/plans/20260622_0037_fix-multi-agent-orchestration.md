# Plano: Corrigir Orquestração Multi-Agent

## Objetivo

Corrigir 3 issues CRÍTICOS, 5 IMPORTANTES e priorizar 7 sugestões identificadas na code review do sistema multi-agent. O resultado é um sistema com permissões coerentes, retry loops com detecção de ciclos, orçamento global de pipeline, e qualidade agnóstica a framework.

## Escopo

- **Dentro:** Permissões de agentes, retry logic, quality checks, cleanup delegation, language consistency, executing-plans skill
- **Fora:** Structured logging avançado (S1), context windowing (S2), audit trail (S3), RBAC (S5), crash recovery (S6)

## Assumptions

1. O sistema multi-agent roda via opencode com Task tool para subagentes
2. `git checkout -b` é a única exceção de escrita git que task-build precisa diretamente
3. Quality checks devem ser auto-detectados via package.json/Makefile/pyproject.toml
4. O executing-plans skill é carregado por dev e task-build — dependências faltantes causarão falha
5. git-commit.md traduzido para PT-BR não altera comportamento (commits permanecem em EN)

## Dependências

- **Pré-requisitos:** Nenhum — todas as mudanças são em arquivos existentes
- **Ordem:** Tasks 1-3 (CRITICAL) primeiro → Tasks 4-8 (IMPORTANT) → Tasks 9-10 (Suggestions)
- **Task 4 depende de Task 3** (cleanup delegation depende de budget global)

## Tasks

### Task 1: [C1] Resolver contradição task-build × git permissions

- **Acceptance:** task-build.md não executa `git checkout -b` nem `git checkout main && git branch -D` diretamente; opencode.json permite `git checkout -b*` para task-build; cleanup delegado para git-commit
- **Verify:** `git checkout -b` e `git branch -D` não aparecem como comandos executados em task-build.md
- **Files:** `task-build.md`, `opencode.json`
- **Complexidade:** média

**Mudanças em `task-build.md`:**
1. Na seção "Regras > Orquestração", remover a exceção "Criação de branch (step 5b) é a ÚNICA exceção"
2. Na seção 5b, reescrever para delegar criação de branch via git-commit:
   - Em vez de `git checkout -b <branch>`, chamar git-commit com prompt para criar branch
   - Ou: adicionar `git checkout -b*` como allow explícito no opencode.json (mais simples)
3. Na seção "Cleanup on failure", remover o bloco `"Deletar branch" → git checkout main && git branch -D`
   - Substituir por: delegar para git-commit com prompt "deletar branch feature/<slug>"
4. Remover da regra "NUNCA executar comandos git de escrita" a frase "Criação de branch (step 5b) é a ÚNICA exceção"

**Mudanças em `opencode.json`:**
1. Adicionar `"git checkout -b*": "allow"` na seção bash permissions de task-build
2. Manter `"git branch -d*": "deny"` e `"git branch -D*": "deny"` (cleanup será delegado)
3. Adicionar `"git checkout main": "ask"` (para cleanup via delegação, não execução direta)

### Task 2: [C2] Corrigir permissões git-commit contraditórias

- **Acceptance:** git-commit tem `edit: "deny"` e `write: "deny"` no opencode.json; regras do md são coerentes
- **Verify:** `grep -E '"edit"|"write"' opencode.json` mostra `deny` para git-commit
- **Files:** `opencode.json`, `git-commit.md`
- **Complexidade:** baixa

**Mudanças em `opencode.json`:**
1. Em `agent.git-commit.permission`: trocar `"edit": "ask"` → `"edit": "deny"`
2. Em `agent.git-commit.permission`: trocar `"write": "ask"` → `"write": "deny"`
3. Adicionar `"git checkout -b*": "allow"` (git-commit cria branches quando delegado)
4. Adicionar `"git branch -d*": "allow"` e `"git branch -D*": "allow"` (cleanup delegation)
5. Adicionar `"git checkout main": "allow"` (para merge workflow)

**Mudanças em `git-commit.md`:**
1. Traduzir para PT-BR (I5) — manter messagens de commit em EN
2. Adicionar seção "Responsabilidades expandidas":
   - Criar feature branches quando delegado por task-build
   - Deletar branches stale quando delegado por task-build
   - Fazer merge quando solicitado
3. Manter regra: "NÃO modificar código fonte ou testes"

### Task 3: [C3] Adicionar state hashing nos retry loops

- **Acceptance:** task-build detecta se output do dev é idêntico ao anterior (stuck loop); se hash não mudou após 2 tentativas iguais, interrompe com mensagem clara
- **Verify:** Simular 3 tentativas idênticas → pipeline interrompe com "mesmo output detectado"
- **Files:** `task-build.md`
- **Complexidade:** média

**Mudanças em `task-build.md`:**
1. Adicionar seção "Detecção de Ciclos" após "Auto-correção":
   ```
   ### Detecção de Ciclos (state hashing)
   Após cada tentativa de dev + code-review:
   1. Gerar hash do output do dev (arquivos alterados + resumo)
   2. Comparar com hash da tentativa anterior
   3. Se hash_identicos ≥ 2 vezes consecutivas → INTERROMPER
   4. Usar QUESTION TOOL:
      - Header: "Loop detectado — mesmo output produzido"
      - Options:
        - "Forçar abordagem diferente" → dev recebe contexto adicional
        - "Pular task" → continua com warning
        - "Parar build" → interrompe pipeline
   ```
2. Atualizar seção 6c para incluir verificação de hash antes de retry automático
3. Adicionar no relatório final coluna "Loops detectados"

### Task 4: [I1] Delegar cleanup para git-commit

- **Acceptance:** task-build não executa `git checkout main` nem `git branch -D` diretamente; cleanup é feito via delegação para git-commit
- **Verify:** `grep -n "git checkout main\|git branch -D" task-build.md` retorna zero resultados (exceto referências textuais em documentação)
- **Files:** `task-build.md`, `git-commit.md`
- **Complexidade:** baixa

**Mudanças em `task-build.md`:**
1. Na seção "Cleanup on failure", reescrever opção "Deletar branch":
   ```
   - "Deletar branch" → delegar para git-commit:
     task(subagent_type="git-commit", 
          description="Deletar branch feature/<slug>",
          prompt="Delete branch feature/<slug>. Execute: git checkout main && git branch -D feature/<slug>")
   ```
2. Na seção "Regras > Orquestração": remover qualquer menção a execução direta de git checkout/branch por task-build

**Mudanças em `git-commit.md`:**
1. Adicionar seção "Responsabilidades de Cleanup" que documenta quando git-commit deve deletar branches

### Task 5: [I2] Tornar quality checks agnósticos a framework

- **Acceptance:** code-review não tem comandos hardcoded de poetry/flake8/pytest; auto-detecta via package.json/pyproject.toml/Makefile
- **Verify:** code-review.md não contém "poetry run black" nem "poetry run flake8" nem "poetry run pytest"
- **Files:** `code-review.md`
- **Complexidade:** média

**Mudanças em `code-review.md`:**
1. Substituir seção 4 hardcoded por seção de auto-detect:
   ```
   ### 4. Quality Checks (auto-detect)
   
   Detectar stack do projeto e rodar comandos apropriados:
   
   **Python (pyproject.toml ou poetry.lock existe):**
   - Formato: `ruff format --check .` ou `black --check .`
   - Lint: `ruff check .` ou `flake8 .`
   - Teste: `pytest --tb=short -q`
   
   **Node.js (package.json existe):**
   - Build: `npm run build` (se script existir)
   - Lint: `npm run lint` (se script existir)
   - Teste: `npm test` (se script existir)
   
   **Makefile existe:**
   - Rodar `make lint`, `make test`, `make build` se targets existirem
   
   **Se nenhum detectado:**
   - Reportar "Nenhum quality check configurado" como Sugestão
   - Não falhar pipeline por isso
   ```
2. Atualizar seção "Regras" para mencionar auto-detect
3. Atualizar formato do relatório para refletir checks detectados

### Task 6: [I3] Adicionar orçamento global de pipeline

- **Acceptance:** task-build tem cap global de 20 tentativas (soma de todas as tasks × retries); ao atingir, interrompe com mensagem clara
- **Verify:** Simular 10 tasks × 3 retries cada → interrompe no retry 7 global (20 total)
- **Files:** `task-build.md`
- **Complexidade:** baixa

**Mudanças em `task-build.md`:**
1. Adicionar constante no topo: `ORÇAMENTO_GLOBAL: 20 tentativas`
2. Na seção 6c, após cada retry, incrementar contador global
3. Quando contador atingir 20:
   ```
   ORÇAMENTO ESGOTADO: 20 tentativas totais atingidas.
   Usar QUESTION TOOL:
   - Header: "Orçamento global esgotado"
   - Options:
     - "Aprovar entregas parciais" → commit o que foi aprovado
     - "Parar build" → interrompe pipeline
   ```
4. Incluir contador no relatório final

### Task 7: [I4] Corrigir executing-plans skill — dependências faltantes

- **Acceptance:** executing-plans não referencia `using-git-worktrees`, `writing-plans`, `finishing-a-development-branch`; ou cria stubs para elas
- **Verify:** `grep -n "using-git-worktrees\|finishing-a-development-branch" executing-plans/SKILL.md` retorna zero
- **Files:** `.config/opencode/skills/executing-plans/SKILL.md`
- **Complexidade:** baixa

**Mudanças em `executing-plans/SKILL.md`:**
1. Na seção "Integration", remover as 3 referências obrigatórias
2. Substituir por:
   ```
   ## Integration
   
   **Optional workflow skills (use if available):**
   - **git-commit** — Para commits ao final do desenvolvimento
   - **code-review** — Para revisão antes de merge
   
   **Nota:** Este skill não depende de outras skills para funcionar.
   O workflow básico (load → execute → report) é auto-contido.
   ```
3. Na seção "Step 3: Complete Development", remover referência a finishing-a-development-branch
   - Substituir por: "Delegar commit para git-commit agent"

### Task 8: [I5] Traduzir git-commit.md para PT-BR

- **Acceptance:** git-commit.md escrito em PT-BR (mantendo comandos git e mensagens de commit em EN)
- **Verify:** Seções principais em PT-BR; comandos git e formato de commit em EN
- **Files:** `.config/opencode/agents/git-commit.md`
- **Complexidade:** baixa

**Mudanças em `git-commit.md`:**
1. Traduzir todos os parágrafos descritivos para PT-BR
2. Manter em EN: comandos git, formato de mensagem de commit, exemplos
3. Alinhar estilo com outros agentes (task-build, dev, code-review, task-planner)

### Task 9: [S7] Adicionar circuit breaker para failures repetidas (vinculado a C3)

- **Acceptance:** task-build implementa circuit breaker: após 3 failures consecutivas de mesma task, abre circuito e pula para próxima
- **Verify:** Simular 3 failures consecutivas → circuito abre, task é pulada
- **Files:** `task-build.md`
- **Complexidade:** baixa

**Mudanças em `task-build.md`:**
1. Integrar com state hashing (Task 3): se hash idêntico 3 vezes → circuit breaker abre
2. Adicionar regra: "Circuit breaker é resetado quando nova task começa"
3. Incluir status do circuit breaker no relatório final

### Task 10: [S4] Simplificar triple-check de backlog

- **Acceptance:** task-build não tem step 6b1 separado; verificação de backlog é feita apenas por code-review
- **Verify:** task-build.md não contém "6b1" nem "Verificar marcação de TODOs"
- **Files:** `task-build.md`
- **Complexidade:** baixa

**Mudanças em `task-build.md`:**
1. Remover seção 6b1 inteira ("Verificar marcação de TODOs no backlog")
2. Manter apenas code-review como verificador de backlog (já faz isso na seção 3a)
3. Simplificar pipeline: dev → code-review (sem step intermediário)

✅ **Concluído** — step 6b1 removido, verificação de backlog consolidada em code-review (seção 3a).

## Sugestões adiadas (não incluídas neste plano)

| Sugestão | Motivo do adiamento |
|---|---|
| S1: Structured logging JSON | Requer mudança de formato de log em todos os agentes — fazer após estabilização |
| S2: Context windowing para diffs grandes | Implementação complexa, low priority agora |
| S3: Audit trail | Depende de S1 (structured logging) |
| S5: RBAC entre agents | Feature avançada, sistema atual com 5 agents não precisa |
| S6: Crash recovery | Requer persistência de estado, depende de arquitetura mais robusta |

## Riscos

| Risco | Mitigação |
|---|---|
| Mover `git checkout -b` para delegação pode quebrar criação de branch | Testar fluxo completo task-build → git-commit → branch criada |
| git-commit com edit/write deny pode impedir criação de arquivos auxiliares | Verificar se git-commit precisa criar algo além de commits (não deveria) |
| Auto-detect de quality checks pode falhar para projetos não-padrão | Fallback: "nenhum check detectado" é warning, não erro |
| executing-plans ao remover dependências pode quebrar workflows existentes | Skill já não funcionava antes (dependências faltantes) — removê-las melhora |
| Tradução PT-BR do git-commit pode introduzir erros de tradução | Revisar cuidadosamente, manter comandos em EN |

## Ordem de Implementação

```
1. Task 8  (I5)  — Traduzir git-commit.md (preparação)
2. Task 2  (C2)  — Corrigir permissões git-commit (opencode.json)
3. Task 1  (C1)  — Resolver contradição task-build (opencode.json + task-build.md)
4. Task 4  (I1)  — Delegar cleanup para git-commit (task-build.md + git-commit.md)
5. Task 7  (I4)  — Corrigir executing-plans (skill)
6. Task 5  (I2)  — Quality checks agnósticos (code-review.md)
7. Task 3  (C3)  — State hashing (task-build.md)
8. Task 9  (S7)  — Circuit breaker (task-build.md)
9. Task 6  (I3)  — Orçamento global (task-build.md)
10. Task 10 (S4)  — Simplificar backlog check (task-build.md)
```

## Verificação Final

Após todas as tasks:

1. **Permissões:** `opencode.json` coerente com regras de cada .md
2. **Retry loops:** Simular 3 outputs idênticos → detecta ciclo
3. **Quality checks:** Rodar em projeto Node.js e Python → ambos funcionam
4. **Pipeline budget:** 20 tentativas globais enforced
5. **executing-plans:** Skill carrega sem erros de dependência
6. **Consistência:** Todos os agentes em PT-BR (comandos em EN)
7. **Cleanup:** Branch deletion via git-commit, não task-build
8. **Nenhuma mudança funcional perdida:** Todos os workflows existentes preservados

## Arquivos afetados

| Arquivo | Tasks |
|---|---|
| `.config/opencode/agents/task-build.md` | 1, 3, 4, 6, 9, 10 |
| `.config/opencode/agents/git-commit.md` | 2, 4, 8 |
| `.config/opencode/agents/code-review.md` | 5 |
| `opencode.json` | 1, 2 |
| `.config/opencode/skills/executing-plans/SKILL.md` | 7 |

**Total: 5 arquivos, 10 tasks**
