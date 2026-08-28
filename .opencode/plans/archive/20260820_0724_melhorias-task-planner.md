# Plano: Melhorias no task-planner.md

## Objetivo

Adicionar 10 melhorias fundamentais ao agente `task-planner.md` para torná-lo um planejador mais estruturado, com decomposição explícita, dependências mapeadas, critérios de aceitação concretos, avaliação de risco formal, checkpoints e anti-padrões. Baseado em pesquisas Anthropic 2024-2026, padrões planner-worker, e gaps identificados no agente atual.

## Escopo

- **Dentro**: Apenas o arquivo `.config/opencode/agents/task-planner.md` (248 linhas → ~450 linhas estimadas)
- **Fora**: Nenhum outro agente, skill ou arquivo do projeto será modificado

## Assumptions

1. O `task-planner.md` é um agente subagent que recebe tarefas via Task tool
2. O `dev` já tem anti-padrões, decomposição e stop conditions definidos — o task-planner precisa de equivalência
3. O `task-build` já define orçamento global, retry policy e circuit breaker — o task-planner não precisa duplicar isso
4. O `plan-reviewer` skill já valida executabilidade do plano — as melhorias devem ser complementares, não conflitantes
5. O formato de plano adaptativo (simples/médio/complexo) existente será preservado e expandido
6. A regra de "nunca implementar" (ADR-004) permanece inalterada

## Dependências

- **Pré-requisitos**: Nenhum — todas as mudanças são em arquivo único
- **Ordem**: As 10 tasks são independentes e podem ser implementadas em qualquer ordem. Recomenda-se a ordem numérica pois cada task constrói sobre as anteriores conceitualmente.

## Tasks

- [ ] **Task 1: Adicionar framework de critérios de aceitação (step 3)**
  - **Onde**: Seção "3. Entender a tarefa", após a linha 112 ("Definir success criteria concretos e testáveis")
  - **O que**: Inserir subseção "#### 3a. Critérios de Aceitação" com:
    - Definição de padrão S.M.A.R.T. para acceptance criteria
    - Formato obrigatório: `Given [contexto] / When [ação] / Then [resultado esperado]`
    - Exemplo concreto de boa vs. má aceitação
    - Regra: toda task DEVE ter pelo menos 1 critério verificável
  - **Acceptance**: Step 3 contém subseção "3a. Critérios de Aceitação" com padrão Given/When/Then, exemplo e regra
  - **Verify**: `grep -n "3a. Critérios de Aceitação" .config/opencode/agents/task-planner.md` → 1 resultado
  - **Files**: `.config/opencode/agents/task-planner.md` (linhas 110-114 → inserir ~15 linhas)
  - **Complexidade**: Baixa

- [ ] **Task 2: Adicionar framework de complexidade com escala numérica (step 6)**
  - **Onde**: Seção "6. Gerar plano adaptativo", após a definição dos 3 formatos (linha ~193)
  - **O que**: Inserir subseção "#### 6a. Escala de Complexidade" com:
    - Escala numérica: Baixa (1-2 arquivos, <30min), Média (3-5, 30-90min), Alta (6+, >90min)
    - Critérios objetivos: arquivos afetados, dependências cruzadas, risco de regressão, necessidade de migração
    - Tabela de decisão: "Se X+Y+Z → Classificação"
    - Regra: complexidade determina formato do plano (simples/médio/complexo)
  - **Acceptance**: Seção 6a existe com escala numérica, critérios objetivos e tabela de decisão
  - **Verify**: `grep -n "6a. Escala de Complexidade" .config/opencode/agents/task-planner.md` → 1 resultado
  - **Files**: `.config/opencode/agents/task-planner.md` (linha ~193 → inserir ~25 linhas)
  - **Complexidade**: Baixa

- [ ] **Task 3: Adicionar metodologia de decomposição estruturada (step 6)**
  - **Onde**: Seção "6. Gerar plano adaptativo", ANTES dos templates de formato (linha ~137)
  - **O que**: Inserir subseção "#### 6.1 Decomposição de Tarefas" com:
    - Instrução explícita de COMO decompor uma tarefa em tasks menores
    - Heurística: "Cada task deve ser completável em uma sessão focada e não deve modificar mais que ~5 arquivos"
    - Técnica de granulação: identificar unidades de mudança (arquivo por arquivo quando possível)
    - Regra de dependência: "Se task B depende de A, B deve vir DEPOIS de A na sequência"
    - Anti-pattern: "NÃO agrupar mudanças em arquivos não relacionados na mesma task"
  - **Acceptance**: Seção 6.1 existe com heurística de granulação, técnica de decomposição e anti-pattern
  - **Verify**: `grep -n "6.1 Decomposição de Tarefas" .config/opencode/agents/task-planner.md` → 1 resultado
  - **Files**: `.config/opencode/agents/task-planner.md` (linha ~137 → inserir ~20 linhas)
  - **Complexidade**: Média

- [ ] **Task 4: Adicionar seção de análise de dependências (templates complexo)**
  - **Onde**: Template "Tarefa complexa" (linhas 172-193), após "## Dependências"
  - **O que**: Expandir a seção "## Dependências" existente com:
    - Formato de matriz de dependências: "Task 2 depende de Task 1 (premissa: schema existe)"
    - Instrução: "Mapear dependências ANTES de gerar a ordem de implementação"
    - Regra: "Se A depende de B, A NÃO pode ser executada antes de B"
    - Exemplo de matriz de dependências para tarefa complexa
    - Nota: para templates simples/médio, dependências são implícitas na ordem
  - **Acceptance**: Template complexo contém matriz de dependências com formato, instrução, regra e exemplo
  - **Verify**: `grep -n "Matriz de Dependências" .config/opencode/agents/task-planner.md` → 1 resultado
  - **Files**: `.config/opencode/agents/task-planner.md` (linhas 178-183 → expandir ~15 linhas)
  - **Complexidade**: Média

- [ ] **Task 5: Adicionar framework de avaliação de risco (templates médio e complexo)**
  - **Onde**: Template "Tarefa média" e "Tarefa complexa", seção "## Riscos" (linhas 168 e 189)
  - **O que**: Expandir seção "## Riscos" com:
    - Framework de 3 dimensões: Probabilidade (Baixa/Média/Alta) × Impacto (Baixo/Médio/Alto) × Mitigação
    - Instrução: "Avaliar cada risco usando as 3 dimensões. Risco com Impacto Alto + Probabilidade Média/Alta SEMPRE requer mitigação explícita"
    - Formato: `- {Risco} | Prob: {B/M/A} | Impacto: {B/M/A} → Mitigação: {ação}`
    - Regra: "Mínimo 2 riscos para tarefas médias, mínimo 3 para tarefas complexas"
    - Exemplo: risco de regressão, risco de dependência quebrada
  - **Acceptance**: Ambos templates contêm framework de 3 dimensões com formato, regra e exemplo
  - **Verify**: `grep -n "Prob:" .config/opencode/agents/task-planner.md` → ≥2 resultados
  - **Files**: `.config/opencode/agents/task-planner.md` (linhas 168 e 189 → expandir ~20 linhas)
  - **Complexidade**: Média

- [ ] **Task 6: Adicionar sistema de checkpoints para planos longos (step 6)**
  - **Onde**: Após o template "Tarefa complexa" (linha ~193), antes de "### 7. Salvar plano"
  - **O que**: Inserir subseção "#### 6b. Checkpoints para Planos Longos" com:
    - Regra: "Planos com >6 tasks DEVEM ter checkpoints após cada 2-3 tasks"
    - Formato do checkpoint: "### Checkpoint {N}: {milestone} — Verificar: {critério}"
    - Instrução: "Cada checkpoint permite ao task-build validar progresso antes de continuar"
    - Checkpoint obrigatório final: "### Checkpoint Final: {todas as tasks concluídas} — Verificar: {testes passam}"
    - Motivação: "Checkpoints habilitam progresso incremental e detecção precoce de problemas" (Anthropic 2025)
  - **Acceptance**: Subseção 6b existe com regra de quando usar, formato de checkpoint e motivação
  - **Verify**: `grep -n "6b. Checkpoints" .config/opencode/agents/task-planner.md` → 1 resultado
  - **Files**: `.config/opencode/agents/task-planner.md` (linha ~193 → inserir ~18 linhas)
  - **Complexidade**: Média

- [ ] **Task 7: Adicionar seção de anti-padrões de planejamento (Regras)**
  - **Onde**: Seção "## Regras" (linha 222), após "### Escopo Absoluto" e antes do final
  - **O que**: Inserir subseção "### Anti-padrões de Planejamento" com tabela similar ao dev agent:
    - `Over-decomposition`: Criar tasks microscopicas (1 linha de código) → Perda de contexto, overhead de review
    - `Under-decomposition`: Tasks gigantes (>10 arquivos) → Impossível review, erros passam despercebidos
    - `Phantom dependencies`: Criar dependências imaginárias → Ordem desnecessariamente restritiva
    - `Missing dependencies`: Não mapear dependências reais → Tasks executadas em ordem errada, erros
    - `Vague acceptance`: Critérios como "funciona bem" → Impossível verificar conclusão
    - `Gold plating`: Adicionar features não solicitadas no plano → Scope creep
    - `Plan without codebase context`: Planejar sem ler o codebase → Reimplementar código existente
    - `Ignoring existing patterns`: Não verificar padrões existentes → Inconsistência
  - **Acceptance**: Tabela de anti-padrões existe com ≥6 entradas, cada uma com Anti-padrão | Consequência | Correção
  - **Verify**: `grep -c "Anti-padrão" .config/opencode/agents/task-planner.md` → ≥8 (incluindo cabeçalho)
  - **Files**: `.config/opencode/agents/task-planner.md` (após linha ~248 → inserir ~25 linhas)
  - **Complexidade**: Baixa

- [ ] **Task 8: Adicionar loop evaluator-optimizer ao workflow (step 6)**
  - **Onde**: Após "#### 6b. Checkpoints" e antes de "### 7. Salvar plano"
  - **O que**: Inserir subseção "#### 6c. Auto-avaliação do Plano" com:
    - Instrução: "ANTES de salvar, o task-planner DEVE auto-avaliar o plano contra 3 critérios"
    - Critério 1: "Completude" — cada requirement da tarefa tem pelo menos 1 task correspondente?
    - Critério 2: "Executabilidade" — cada task tem acceptance criteria e verificação?
    - Critério 3: "Independência" — tasks independentes estão marcadas como paralelas, dependentes em sequência?
    - Se algum critério falhar → refinar o plano ANTES de salvar
    - Máximo 2 iterações de auto-avaliação (evitar loop infinito)
    - Motivação: "Evaluator-optimizer loop garante qualidade antes da revisão externa" (Anthropic 2024)
  - **Acceptance**: Subseção 6c existe com 3 critérios, instrução de refinar e limite de iterações
  - **Verify**: `grep -n "6c. Auto-avaliação" .config/opencode/agents/task-planner.md` → 1 resultado
  - **Files**: `.config/opencode/agents/task-planner.md` (após linha ~211 → inserir ~18 linhas)
  - **Complexidade**: Média

- [ ] **Task 9: Adicionar formato de feature list JSON para progress tracking (step 6)**
  - **Onde**: Após "#### 6c. Auto-avaliação" e antes de "### 7. Salvar plano"
  - **O que**: Inserir subseção "#### 6d. Feature List Estruturada" com:
    - Formato JSON no final do plano para tracking de progresso:
      ```json
      {
        "features": [
          {"id": 1, "name": "task name", "status": "pending", "acceptance": ["criterio1", "criterio2"]}
        ]
      }
      ```
    - Instrução: "Incluir feature list no final do plano. O task-build usa para tracking."
    - Regra: "Cada feature DEVE ter id, name, status e acceptance array"
    - Nota: "Status é sempre 'pending' no plano — atualizado pelo dev durante implementação"
    - Motivação: "Feature list como JSON estruturado habilita progress tracking automático" (Anthropic 2025)
  - **Acceptance**: Subseção 6d existe com formato JSON, instrução e regra
  - **Verify**: `grep -n "6d. Feature List" .config/opencode/agents/task-planner.md` → 1 resultado
  - **Files**: `.config/opencode/agents/task-planner.md` (após linha ~229 → inserir ~18 linhas)
  - **Complexidade**: Baixa

- [ ] **Task 10: Adicionar seção de contexto e motivação ao workflow (step 3)**
  - **Onde**: Seção "3. Entender a tarefa" (linhas 108-114), após a subseção 3a
  - **O que**: Inserir subseção "#### 3b. Contexto e Motivação" com:
    - Instrução: "Sempre incluir no plano: POR QUE esta tarefa existe (motivação) e CONTEXTO relevante"
    - Formato: "## Contexto" no topo do plano, antes de "## Objetivo"
    - Conteúdo: "Que problema resolve? Quem é o usuário afetado? Qual o impacto de NÃO fazer?"
    - Regra: "Planos sem contexto são menos revisáveis — o dev não entende 'por quê' apenas 'o quê'"
    - Motivação: "Contexto e motivação melhoram a qualidade do planejamento" (Claude Prompting 2026)
  - **Acceptance**: Subseção 3b existe com instrução, formato e regra
  - **Verify**: `grep -n "3b. Contexto e Motivação" .config/opencode/agents/task-planner.md` → 1 resultado
  - **Files**: `.config/opencode/agents/task-planner.md` (após linha ~114 → inserir ~15 linhas)
  - **Complexidade**: Baixa

## Riscos

- Ficar muito verboso → Mitigação: Manter templates compactos, usar tabelas em vez de parágrafos; cada task adiciona no máximo 25 linhas
- Conflito com plan-reviewer skill → Mitigação: Melhorias complementam plan-reviewer (preenchimento de campos), não substituem validação
- Aumentar tempo de planejamento → Mitigação: Auto-avaliação (Task 8) tem limite de 2 iterações; features opcionais podem ser ignoradas por tarefas simples
- Dev não consumir feature list JSON → Mitigação: Feature list é opcional para templates simples, obrigatória apenas para complexos; dev já tem sistema de tracking no step 8
- Referências quebradas entre seções → Mitigação: Tasks são independentes; cada uma modifica uma seção distinta sem depender das outras

## Ordem de Implementação

Recomendada (constrói conceitualmente de baixo para cima):
1. **Task 1** (critérios de aceitação) — fundamento para Tasks 3, 6, 8
2. **Task 2** (escala de complexidade) — fundamento para Task 6
3. **Task 3** (decomposição) — fundamento para Tasks 4, 6
4. **Task 4** (dependências) — complementa decomposição
5. **Task 5** (avaliação de risco) — independente, mas enriquece templates
6. **Task 6** (checkpoints) — usa decomposição + complexidade
7. **Task 7** (anti-padrões) — independente, adiciona qualidade
8. **Task 8** (auto-avaliação) — usa critérios de aceitação
9. **Task 9** (feature list) — complementa auto-avaliação
10. **Task 10** (contexto e motivação) — independente, melhora fundamentação

**Nota**: Embora recomendadas nessa ordem, todas as tasks são independentes e podem ser implementadas em paralelo.

## Verificação Final

Após implementação de todas as tasks:
1. `wc -l .config/opencode/agents/task-planner.md` → resultado esperado: ~400-480 linhas (era 248)
2. `grep -c "###\|####" .config/opencode/agents/task-planner.md` → resultado esperado: ≥30 subseções
3. `grep -n "Given\|When\|Then" .config/opencode/agents/task-planner.md` → ≥1 resultado (Task 1)
4. `grep -n "Prob:" .config/opencode/agents/task-planner.md` → ≥2 resultados (Task 5)
5. `grep -n "Over-decomposition\|Gold plating\|Phantom dependencies" .config/opencode/agents/task-planner.md` → ≥3 resultados (Task 7)
6. `grep -n "features.*pending" .config/opencode/agents/task-planner.md` → ≥1 resultado (Task 9)
7. Verificar que seção "### Regras" / "### Escopo Absoluto" permanece inalterada
8. Verificar que templates (simples/médio/complexo) existem e estão expandidos
9. Validar com `plan-reviewer` skill: delegar revisão do arquivo modificado para code-review
