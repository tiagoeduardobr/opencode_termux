# Plano: Corrigir rastreamento de conclusão de TODOs no backlog

## Objetivo

Corrigir as lacunas identificadas no code review que impedem o rastreamento automático da conclusão de TODOs durante o pipeline de entrega. Os problemas incluem: formato de plano incompatível (sem checkboxes), code-review não verificando conclusão, task-build não assegurando atualização do plano, backlog-curator não integrado, e task-planner não validando formato.

## Escopo

- **Dentro**: Modificar `code-review.md`, `task-build.md`, e `task-planner.md` para adicionar verificação de conclusão de TODOs, validação de formato de plano com checkboxes, e integração com backlog-curator.
- **Fora**: Não alterar scripts de shell, configs de projeto, ou outros agentes não mencionados.

## Assumptions

1. O formato de plano com checkboxes (`- [ ]`) é o padrão correto para rastreamento automático
2. O backlog-curator skill deve ser consultado antes de iniciar pipeline para recomendar prioridades
3. A verificação de conclusão de TODOs deve ocorrer tanto no code-review quanto no task-build
4. O task-planner deve forçar o uso de checkboxes em todos os formatos de plano
5. As mudanças são retrocompatíveis — planos existentes continuam funcionando

## Dependências

- **Pré-requisitos**: Nenhum — os arquivos já existem
- **Ordem**: task-planner → task-build → code-review (cada uma depende da anterior para validação encadeada)

## Tasks

### Task 1: Atualizar `task-planner.md` — Enforçar formato com checkboxes
- **Acceptance**: Templates de plano usam `- [ ]` para tasks, e há validação explícita do formato
- **Verify**: Ler task-planner.md e confirmar que todos os templates (simples, médio, complexo) usam `- [ ]`
- **Files**: `.config/opencode/agents/task-planner.md`
- **Complexidade**: baixa

**Mudança具体**:
- Linhas 58-106 (templates de plano): Trocar `### Task N:` por `- [ ] {task}`
- Adicionar seção de validação após o template: "O agente DEVE usar checkboxes `- [ ]` em todas as tasks do plano"
- Garantir que o formato `### Task N:` NÃO seja usado em nenhum template

**Linha específica**:
- Linha 63: `- [ ] {task} — Acceptance: {critério} — Verify: {como confirmar}` (já usa checkbox ✅)
- Linha 76-80: Já usa `- [ ]` ✅
- Linha 97-101: Já usa `- [ ]` ✅

**Problema real**: O template `### Task N:` aparece no plano existente (`20260621_1200_fix-readme-installation-steps.md` linhas 22, 41, 64, 89), mas os templates no task-planner.md já usam `- [ ]`. A inconsistência é que o **exemplo de plano existente** viola o formato. A correção é adicionar uma regra explícita que proíbe `### Task N:` sem checkbox.

**Mudança adicional**: Adicionar na seção "Regras" (após linha 151):
```markdown
- NUNCA usar `### Task N:` sem checkbox — sempre `- [ ] {task}`
- Formato de task inválido = plano rejeitado pelo task-build
```

### Task 2: Atualizar `task-build.md` — Verificar atualização do plano antes de code-review
- **Acceptance**: Após cada task executada, task-build verifica se o plano foi atualizado com `- [x]` antes de delegar para code-review
- **Verify**: Ler task-build.md e confirmar que há passo de verificação de plano entre dev e code-review
- **Files**: `.config/opencode/agents/task-build.md`
- **Complexidade**: baixa

**Mudança具体**:
- Após step 6a (dev) e antes de 6b (code-review), adicionar novo step 6a1: "Verificar plano atualizado"
- O step deve:
  1. Ler o arquivo de plano
  2. Verificar se a task atual tem `- [x]` (marcada como completa)
  3. Se não tiver, atualizar automaticamente o checkbox para `- [x]`
  4. Salvar o plano atualizado
  5. Continuar para code-review

**Inserir entre linhas 91 e 92** (após LOG do dev, antes de delegar para code-review):
```markdown
#### 6a1. Atualizar plano (obrigatório)

Após dev completar task, ATUALIZAR o arquivo de plano:

1. Ler plano de `.opencode/plans/{plano_atual}.md`
2. Encontrar a task executada (por número ou descrição)
3. Marcar checkbox: trocar `- [ ]` por `- [x]` na linha da task
4. Salvar plano atualizado
5. LOG: `[HH:MM] plano → task N marcada como completa → OK`

**Se plano não for encontrado** → WARNING no relatório final (não bloqueia pipeline)
```

### Task 3: Atualizar `code-review.md` — Adicionar verificação de conclusão de TODOs
- **Acceptance**: Code-review verifica se todas as tasks do plano foram marcadas como `- [x]` antes de dar veredito "Aprovado"
- **Verify**: Ler code-review.md e confirmar que há step de verificação de TODOs no plano
- **Files**: `.config/opencode/agents/code-review.md`
- **Complexidade**: baixa

**Mudança具体**:
- Adicionar novo step entre step 3 (Contexto) e step 4 (Quality Checks): step 3b "Verificar conclusão de TODOs"
- O step deve:
  1. Ler o arquivo de plano encontrado no step 3
  2. Contar total de tasks (`- [ ]` + `- [x]`)
  3. Contar tasks completadas (`- [x]`)
  4. Se houver tasks não completadas que deveriam estar (baseado no escopo do diff), reportar como "Crítico"
  5. Incluir estatísticas no relatório

**Inserir entre linhas 36 e 38** (após "Se encontrado: comparar", antes de "Quality Checks"):
```markdown
### 3b. Verificar conclusão de TODOs (obrigatório quando há plano)

Se um plano foi encontrado no step 3:

1. Ler o arquivo de plano
2. Contar: `total_tasks` = linhas com `- [ ]` + `- [x]`
3. Contar: `completed_tasks` = linhas com `- [x]`
4. Calcular: `completion_rate` = completed_tasks / total_tasks
5. Se `completion_rate < 1.0` e há diff relevante para tasks incompletas:
   - Adicionar em **Críticos**: "Plano tem {total - completed} tasks não marcadas como concluídas"
   - Sugerir: "Verificar se as tasks foram implementadas mas não marcadas no plano"
6. Incluir no relatório: `Plano: {completed}/{total} tasks concluídas ({rate}%)`
```

### Task 4: Integrar `backlog-curator` no `task-build.md`
- **Acceptance**: task-build consultar backlog-curator antes de iniciar pipeline para obter recomendações de prioridade
- **Verify**: Ler task-build.md e confirmar que há chamada ao backlog-curator no início do workflow
- **Files**: `.config/opencode/agents/task-build.md`
- **Complexidade**: média

**Mudança具体**:
- Adicionar novo step entre step 2 (Receber tarefa) e step 3 (QUESTION TOOL): step 2b "Consultar backlog"
- O step deve:
  1. Verificar se existe `.pm/backlog/items.yaml`
  2. Se existir, carregar skill `backlog-curator`
  3. Analisar backlog para identificar itens relacionados à tarefa
  4. Apresentar recomendações ao usuário (se houver)
  5. Permitir ao usuário adicionar a tarefa ao backlog (opcional)

**Inserir entre linhas 20 e 22** (após "Definir o que é esperado", antes de "QUESTION TOOL"):
```markdown
### 2b. Consultar backlog (opcional)

Verificar se existe backlog configurado:

1. Checar se `.pm/backlog/items.yaml` existe
2. Se existir:
   - Carregar skill `backlog-curator`
   - Analisar itens do backlog relacionados à tarefa
   - Se houver itens relacionados, apresentar via QUESTION TOOL:
     - Header: `"Itens no backlog"`
     - Options:
       - `"Adicionar tarefa ao backlog"` → adicionar com prioridade inferida
       - `"Continuar sem adicionar"` → segue para step 3
3. Se não existir: seguir para step 3 diretamente

**Nota**: Esta etapa é opcional e não bloqueia o pipeline.
```

## Riscos

- **Risco**: Planos existentes (como `20260621_1200_fix-readme-installation-steps.md`) usam formato `### Task N:` sem checkboxes → **Mitigação**: Não alterar planos existentes; a validação aplica-se apenas a novos planos gerados pelo task-planner
- **Risco**: Adicionar verificação de plano no code-review pode aumentar tempo de review → **Mitigação**: A verificação é leve (leitura de arquivo + contagem de linhas)
- **Risco**: Integração com backlog-curator pode falhar se `.pm/backlog/items.yaml` não existir → **Mitigação**: Step é opcional e tratado com fallback graceful
- **Risco**: Atualização automática de checkbox no task-build pode marcar tasks incorretamente → **Mitigação**: Apenas marcar tasks que o dev reportou como concluídas

## Ordem de Implementação

1. **Task 1** (task-planner.md) — Fundação: garante que novos planos tenham checkboxes
2. **Task 2** (task-build.md) — Pipeline: garante que planos sejam atualizados durante execução
3. **Task 3** (code-review.md) — Validação: garante queTODOs sejam verificados na revisão
4. **Task 4** (task-build.md) — Integração: adiciona backlog-curator ao fluxo

## Verificação Final

1. Ler todos os três arquivos modificados e confirmar:
   - `task-planner.md`: Templates usam `- [ ]`, regras proíbem `### Task N:` sem checkbox
   - `task-build.md`: Step 6a1 atualiza plano, step 2b consulta backlog
   - `code-review.md`: Step 3b verifica conclusão de TODOs
2. Gerar um plano de teste com task-planner e confirmar que usa checkboxes
3. Simular execução de task-build e confirmar que plano é atualizado
4. Rodar code-review e confirmar que verifica checkboxes no plano
5. Verificar que nenhum outro conteúdo foi alterado acidentalmente
6. Testar cenário de borda: plano inexistente (fallback graceful)
7. Testar cenário de borda: backlog não configurado (step opcional ignorado)
