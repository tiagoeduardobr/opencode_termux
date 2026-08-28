# Plano: Melhorias no task-build.md (10 tasks)

## Objetivo

Implementar 10 tasks (7 issues: 3 críticos + 5 importantes) identificadas por code-review no workflow do `task-build.md`.
São 3 issues críticos (resiliência/robustez) e 5 importantes (contratos/organização).

## Escopo

- **Dentro**: Alterar `.config/opencode/agents/task-build.md` (509 linhas) e
  `.config/opencode/agents/git-commit.md` (apenas para task I5 — branch-only delegation)
- **Fora**: Não modificar agentes filhos (dev, code-review, task-planner),
  não alterar skills, não modificar scripts Termux, não mexer em AGENTS.md

## Assumptions

1. O arquivo `.config/opencode/agents/task-build.md` é markdown puro (frontmatter YAML + body)
2. O task-build é o único agente `primary` — alterações afetam todo o pipeline
3. Subagentes não precisam de mudanças para receber contratos tipados (prompt encoding)
4. O diretório `.opencode/dead-letter/` não existe ainda e será criado pelo dev
5. A seção "Detecção de Ciclos" (L401-413) e "Circuit Breaker" (L415-426) são seções distintas
6. Não há plano anterior para esta tarefa específica
7. git-commit.md tem step 0b (L52-62) que lida com criação de branch mas NÃO impede
   continuação para o workflow completo de commit/push/merge

## Dependências

- **Pré-requisitos**: Nenhum (tasks editam 2 arquivos markdown distintos)
- **Ordem**: Tasks com dependências parciais — ordem recomendada respeita:
  C2→C1 (retry policy é fundação para circuit breaker),
  C3a→C3b (DLQ define formato para checkpointing),
  I1b→I5 (contrato genérico antes do específico).
  Tasks restantes são independentes. Recomendado: seguir ordem da seção "Ordem de Implementação".

## Tasks

- [ ] **C1. Circuit breaker com HALF_OPEN state**
  - **Seções**: "Detecção de Ciclos" (L401-413) e "Circuit Breaker (falhas em cascata)" (L415-426)
  - **Mudança**: Após circuit breaker abrir (3x output idêntico ou 3+ falhas consecutivas),
    em vez de ir direto para QUESTION TOOL, adicionar:
    1. Recovery timeout de 30 segundos (aguardar)
    2. Transição para estado `HALF_OPEN`
    3. Retry 1x com prompt modificado (instruir dev a usar abordagem diferente)
    4. Se sucesso → circuit breaker fecha (volta ao normal)
    5. Se falha → circuit breaker reabre (QUESTION TOOL como hoje)
  - **Acceptance**: Seção "Detecção de Ciclos" descreve estados OPEN → HALF_OPEN → CLOSED;
    Recovery timeout documentado (30s); Retry em HALF_OPEN menciona "prompt modificado"
  - **Verify**:
    - Run: `grep -n "HALF_OPEN\|recovery timeout\|30s\|fecha" .config/opencode/agents/task-build.md`
    - Expected: deve retornar linhas nas seções L401-424
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: média

- [ ] **C2. Retry policy com backoff exponencial + jitter**
  - **Seção**: Nova subseção "Retry Policy" na seção "Regras" (após L400, antes de "Detecção de Ciclos")
  - **Mudança**: Adicionar regra de retry aplicável a todas as delegações:
    - Backoff exponencial: 2s → 4s → 8s (base × 2^n)
    - Jitter: rand(0, 2^n) segundos (0-1s, 0-2s, 0-4s)
    - Máximo de 3 retries (já existente em vários pontos — consolidar referência)
    - Aplicar a: task-planner (L96-103), dev retries (L250), git-commit retries (L304-308)
  - **Acceptance**: Nova subseção "Retry Policy" existe; backoff exponencial documentado
    com valores (2s, 4s, 8s); jitter documentado; referências a retries existentes
    apontam para esta política central
  - **Verify**:
    - Run: `grep -n "backoff\|jitter\|exponencial" .config/opencode/agents/task-build.md`
    - Expected: deve retornar a nova subseção
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: baixa

- [ ] **C3a. Dead Letter Queue — estrutura e serialização**
  - **Seção**: Nova subseção "Dead Letter Queue" dentro de "Crash Recovery" (L386-395)
  - **Mudança**: Definir mecanismo de dead letter queue para falhas não recuperáveis:
    - Formato: `.opencode/dead-letter/{timestamp}_{task_id}.md`
    - Conteúdo do arquivo: task_id, agente, timestamp, prompt enviado, output parcial,
      erro capturado, tentativas realizadas, contexto (branch, plano)
    - Quando gravar: após esgotar retries (3x) de um agente OU após "Parar build"
      do usuário com trabalho parcial
    - O task-build NÃO cria o diretório — instrui dev a criar se necessário
      (respeitando proibições de edição do task-build)
  - **Acceptance**: Subseção "Dead Letter Queue" existe; formato de path documentado;
    campos do arquivo listados; regra de quando gravar definida
  - **Verify**:
    - Run: `grep -n "dead-letter\|Dead Letter" .config/opencode/agents/task-build.md`
    - Expected: deve retornar a nova subseção
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: média

- [x] **C3b. Crash Recovery — checkpointing serializado**
  - **Seção**: Expandir "Crash Recovery" (L386-395) — refinar step 2
  - **Mudança**: Atualizar a instrução vaga "salvar estado atual" com definição explícita:
    - O QUE serializar: task_id, tentativa atual, output parcial do agente, hash do ciclo,
      contador de retries, branch ativa, timestamp
    - ONDE serializar: referenciar o mesmo path do dead letter queue (`.opencode/dead-letter/`)
    - Formato: markdown estruturado (consistente com o formato de dead letter)
    - Trigger: quando crash recovery step 2 executar, criar arquivo de checkpoint
  - **Acceptance**: Step 2 do crash recovery define campos exatos a serializar;
    path de serialização referenciado; formato markdown documentado
  - **Verify**:
    - Run: `grep -n "checkpoint\|serializar.*estado\|task_id.*tentativa" .config/opencode/agents/task-build.md`
    - Expected: deve retornar linhas na seção L386-395
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: baixa

- [ ] **I1a. Contratos de output — task-planner e dev**
  - **Seção**: Nova subseção "Contratos de Output" na seção "Regras" (após "Retry Policy")
  - **Mudança**: Definir contrato mínimo de output para task-planner e dev:
    - **task-planner**: Output obrigatório = "Plano salvo em {path}. Pronto para revisão."
      + path do plano; Erro = "Falha ao planejar: {motivo}"
    - **dev**: Output obrigatório = lista de arquivos modificados + resumo da implementação
      + confirmação de que marcou backlog; Erro = "Falha ao implementar task {id}: {motivo}"
  - **Acceptance**: Subseção existe; task-planner e dev têm contratos definidos;
    formato de output e erro documentados para cada um
  - **Verify**:
    - Run: `grep -n "Contratos de Output\|task-planner.*output\|dev.*output" .config/opencode/agents/task-build.md`
    - Expected: deve retornar a subseção e contratos definidos
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: baixa

- [ ] **I1b. Contratos de output — code-review e git-commit**
  - **Seção**: Mesma subseção "Contratos de Output" (extensão da I1a)
  - **Mudança**: Definir contrato mínimo para code-review e git-commit:
    - **code-review (plano)**: Output = veredito `[OKAY]` ou `[REJECT]` + motivos
    - **code-review (código)**: Output = "Aprovado" / "Aprovação condicional" / "Precisa de ajustes" + detalhes
    - **git-commit**: Output = hash do commit + branch; Erro = "Falha no commit: {motivo}"
  - **Acceptance**: code-review e git-commit têm contratos definidos; veredistos
    padronizados listados para code-review; git-commit output definido
  - **Verify**:
    - Run: `grep -n "code-review.*output\|git-commit.*output\|OKAY\|REJECT" .config/opencode/agents/task-build.md`
    - Expected: deve retornar contratos de code-review e git-commit
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: baixa

- [ ] **I5. Branch-only delegation — contrato explícito para criação de branch**
  - **Seções**:
    1. `task-build.md` step 5b (L185-190) — refinar prompt de delegação ao git-commit
    2. `git-commit.md` step 0b (L52-62) — adicionar guard para modo branch-only
  - **Mudança**:
    - **task-build.md** (step 5b, L189): Atualizar o prompt de delegação para incluir
      instrução explícita de que git-commit deve APENAS criar a branch:
      ```
      prompt="Criar e checkout branch {branch}. Execute: git checkout -b {branch}.
      NÃO executar commit, push, merge ou sugerir implementação.
      Retornar APENAS confirmação de que a branch foi criada (formato: 'Branch {branch} criada com sucesso')."
      ```
    - **git-commit.md** (step 0b, L52-62): Adicionar nota no step 0b indicando que
      quando o prompt contiver "NÃO executar commit" (ou equivalente), o agente deve:
      1. Criar a branch (git checkout -b)
      2. Verificar com `git branch --show-current`
      3. Retornar confirmação (formato: "Branch {branch} criada com sucesso")
      4. NÃO prosseguir para step 1 (QUESTION TOOL), nem steps subsequentes
      5. Tratar este como "modo branch-only" — retorno imediato após criação
  - **Acceptance**:
    - task-build.md step 5b contém instrução "NÃO executar commit, push, merge"
    - git-commit.md step 0b contém nota sobre "modo branch-only" com retorno imediato
    - Ambos os arquivos têm a restrição documentada
  - **Verify**:
    - Run: `grep -n "NÃO.*commit\|NÃO.*push\|apenas.*branch\|somente.*branch\|modo branch-only" .config/opencode/agents/task-build.md .config/opencode/agents/git-commit.md`
    - Expected: deve retornar restrições de branch-only em ambos os arquivos
  - **Files**: `.config/opencode/agents/task-build.md`, `.config/opencode/agents/git-commit.md`
  - **Complexidade**: baixa

- [ ] **I2. Context budgeting no step 0**
  - **Seção**: Step 0 "Ler AGENTS.md" (L49-63)
  - **Mudança**: Refinar a instrução de incluir AGENTS.md nos prompts de subagentes:
    - Em vez de "incluir trecho relevante do AGENTS.md", definir regra explícita:
      - MÁXIMO 200 linhas de AGENTS.md por prompt de subagente
      - Incluir APENAS seções aplicáveis: "Convenções e Gotchas" (se scripts Termux),
        "Agent Workflow" (se orquestração), "Leitura Recomendada por Tarefa"
      - Se tarefa não é sobre scripts Termux, NÃO incluir seção "Convenções e Gotchas"
      - Referência: "Budget de contexto: ~200 linhas por subagente"
  - **Acceptance**: Step 0 menciona budget explícito (200 linhas); regra de filtragem
    por seção documentada; motivo (economia de tokens) justificado
  - **Verify**:
    - Run: `grep -n "200 linhas\|budget\|APENAS.*seção" .config/opencode/agents/task-build.md`
    - Expected: deve retornar definição de budget e regras de filtragem
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: baixa

- [ ] **I3. Checkpointing — formato expandido no crash recovery**
  - **Seção**: Integrado com C3b — expandir step 2 do crash recovery
  - **Mudança**: Adicionar formato de checkpoint que permite retomada:
    - Campo `resumivel: true/false` — indica se a task pode ser retomada
    - Campo `proximo_passo` — qual step do workflow retomar (6a, 6b, etc.)
    - Campo `contexto_necessario` — dados que o agente precisa ao retomar
    - Exemplo de checkpoint serializado no próprio markdown
  - **Acceptance**: Checkpoint inclui campos `resumivel`, `proximo_passo`, `contexto_necessario`;
    exemplo de checkpoint presente na documentação
  - **Verify**:
    - Run: `grep -n "resumivel\|proximo_passo\|contexto_necessario" .config/opencode/agents/task-build.md`
    - Expected: deve retornar campos expandidos de checkpoint
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: baixa

- [ ] **I4. Routing table — tipo de tarefa → agente → pipeline**
  - **Seção**: Nova subseção "Routing" no início da seção "Workflow" (após L47, antes do step 0)
  - **Mudança**: Adicionar tabela de roteamento explícita:
    | Tipo de Tarefa | Agente(s) | Pipeline |
    |----------------|-----------|----------|
    | Feature complexa (3+ arquivos) | task-build (orquestra) | task-planner → dev → code-review → git-commit |
    | Fix pontual (1-2 arquivos) | dev + git-commit | dev → git-commit |
    | Revisão de código | code-review | code-review → relatório |
    | Criar plano | task-planner | task-planner → plan-reviewer → code-review |
    | Criar commit | git-commit | git-commit |
    | Criar branch (isolado) | git-commit | git-commit (branch-only) |
    | Debug/systematic | dev | dev → systematic-debugging |
  - **Acceptance**: Tabela de routing presente; pelo menos 6 cenários documentados;
    cada cenário mapeia tipo → agente(s) → pipeline; cenário "Criar branch (isolado)" presente
  - **Verify**:
    - Run: `grep -n "Routing\|tipo de tarefa\|pipeline\|branch.*isolado" .config/opencode/agents/task-build.md`
    - Expected: deve retornar tabela de routing com pelo menos 6 cenários
  - **Files**: `.config/opencode/agents/task-build.md`
  - **Complexidade**: baixa

## Riscos

- **Conflito de edições**: Todas as tasks editam o(s) mesmo(s) arquivo(s) mas seções distintas.
  Risco baixo — se executadas em sequência, não há conflito.
  → Mitigação: executar tasks em ordem (C1 → C2 → C3a → C3b → I1a → I1b → I5 → I2 → I3 → I4)

- **Multi-file edit (I5)**: Task I5 edita 2 arquivos distintos (task-build.md + git-commit.md).
  Risco baixo — seções são independentes e não há dependência de conteúdo entre elas.
  → Mitigação: I5 pode ser executada após I1b (que já define o contrato genérico de git-commit);
  verificar ambos os arquivos com grep após implementação

- **Breaking o frontmatter YAML**: Edições na seção "Regras" (L335+) não afetam o frontmatter (L1-40).
  Risco baixo.
  → Mitigação: verificar que frontmatter permanece intacto após cada task (grep por `---`)

- **Referências cruzadas quebradas**: Adicionar subseções pode deslocar números de linha.
  Risco baixo — o plano usa descrições de seção, não números de linha exatos.
  → Mitigação: verificar com `grep` que seções pai existem antes de inserir filhas

## Ordem de Implementação

Recomendada (críticos primeiro, depois importantes):

1. C2 (retry policy) — fundação para C1
2. C1 (circuit breaker HALF_OPEN) — usa retry policy
3. C3a (dead letter queue — estrutura) — define path/formato
4. C3b (crash recovery — checkpointing) — reusa formato do C3a
5. I1a (contratos — task-planner + dev)
6. I1b (contratos — code-review + git-commit)
7. I5 (branch-only delegation — task-build + git-commit)
8. I2 (context budgeting)
9. I3 (checkpointing — campos expandidos)
10. I4 (routing table)

## Verificação Final

```bash
# Verificar que todas as subseções foram criadas
grep -n "Retry Policy\|HALF_OPEN\|Dead Letter Queue\|Contratos de Output\|Routing\|200 linhas\|resumivel" \
  .config/opencode/agents/task-build.md

# Verificar que o frontmatter não foi alterado
head -40 .config/opencode/agents/task-build.md | grep "^---$" | wc -l
# Deve retornar 2 (abertura e fechamento)

# Verificar que a seção "Regras" contém as novas subseções
grep -n "### Retry Policy\|### Contratos de Output\|### Dead Letter Queue" \
  .config/opencode/agents/task-build.md

# Verificar que o arquivo não perdeu a seção "Timeout" (L500-509)
grep -n "Timeout\|task-planner.*5 min\|dev.*10 min" .config/opencode/agents/task-build.md

# Verificar branch-only delegation (I5) em ambos os arquivos
grep -n "NÃO.*commit\|NÃO.*push\|apenas.*branch\|somente.*branch\|modo branch-only" \
  .config/opencode/agents/task-build.md .config/opencode/agents/git-commit.md

# Contar linhas totais (deve ser > 509 em task-build.md e > 119 em git-commit.md após todas as adições)
wc -l .config/opencode/agents/task-build.md .config/opencode/agents/git-commit.md
```
