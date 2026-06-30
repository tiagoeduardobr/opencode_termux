# Plano: Limpeza e Atualização do AGENTS.md

## Objetivo

Remover redundâncias, duplicidades e informações desatualizadas do AGENTS.md, mantendo-o conciso e preciso como referência para agentes de IA.

## Escopo

- **Dentro**: Limpeza de duplicidades, simplificação de seções redundantes, remoção de "Melhorias Recentes" redundante
- **Fora**: Alteração de funcionalidades, adição de novas seções, modificação de workflows

## Assumptions

1. O AGENTS.md é lido por agentes de IA como contexto principal
2. As informações detalhadas já estão nos prompts dos agentes (task-build.md, dev.md, etc.)
3. O MULTI_AGENT_ORCHESTRATION.md é a referência completa para deep-dive
4. Manter o AGENTS.md enxuto melhora a performance de carregamento

## Tasks

### Task 1: Remover duplicidade "Referências Doc por Fluxo" (Prioridade: ALTA)

- **Descrição**: Remover seção "Referências Doc por Fluxo" (linhas 282-291) que é idêntica a "Leitura Recomendada por Tarefa" (linhas 180-189)
- **Acceptance**: Seção removida, sem perda de informação
- **Verify**: Comparar linhas antes/depois; verificar que "Leitura Recomendada por Tarefa" permanece
- **Files**: `AGENTS.md`
- **Complexidade**: Baixa
- **Status**: ✅ Concluído em [29/06/2026:22:13]

### Task 2: Simplificar "Melhorias Recentes" (Prioridade: MÉDIA)

- **Descrição**: Simplificar seção "Melhorias Recentes" (linhas 301-314) para apenas referenciar MULTI_AGENT_ORCHESTRATION.md
- **Acceptance**: Seção reduzida para 2-3 linhas com referência
- **Verify**: Verificar que informações relevantes estão em MULTI_AGENT_ORCHESTRATION.md
- **Files**: `AGENTS.md`
- **Complexidade**: Baixa
- **Status**: ✅ Concluído em [30/06/2026:08:11]

### Task 5: Comparar referências RBAC com MULTI_AGENT_ORCHESTRATION.md (Prioridade: ALTA)

- **Descrição**: Comparar referências RBAC com MULTI_AGENT_ORCHESTRATION.md. Se inconsistência, corrigir.
- **Acceptance**: Descrição RBAC nas linhas 149-152, 211 e 306 do AGENTS.md corresponde à seção 5 do MULTI_AGENT_ORCHESTRATION.md
- **Verify**: Comparar seção 'RBAC syntax no opencode.json' (linhas 149-152), menção na linha 211 e seção 'RBAC' (linha 306) com seção 5 do MULTI_AGENT_ORCHESTRATION.md; corrigir inconsistências
- **Files**: `AGENTS.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`
- **Complexidade**: Média
- **Status**: ✅ Concluído em [29/06/2026:22:10]

### Task 3: Comparar loop de trabalho com task-build.md (Prioridade: MÉDIA)

- **Descrição**: Comparar loop de trabalho (seção "Loop de trabalho", linhas 258-276) com task-build.md. Se divergências, documentar e decidir qual versão manter.
- **Acceptance**: Linhas 258-276 do AGENTS.md correspondem ao workflow do task-build.md (steps 0-8)
- **Verify**: Comparar steps do loop (seção "Loop de trabalho") com workflow do task-build.md; verificar que divergências foram documentadas
- **Files**: `AGENTS.md`, `.config/opencode/agents/task-build.md`
- **Complexidade**: Média

### Task 4: Comparar regras de delegação com prompts dos agentes (Prioridade: MÉDIA)

- **Descrição**: Comparar regras de delegação (seção "Regras de delegação", linhas 238-244) com prompts dos agentes. Se duplicação, remover do AGENTS.md.
- **Acceptance**: Regras 1-5 do AGENTS.md não repetem informações já presentes nos prompts dos agentes
- **Verify**: Comparar regras de delegação (seção "Regras de delegação") com prompts dos agentes; verificar que duplicações foram removidas
- **Files**: `AGENTS.md`, `.config/opencode/agents/*.md`
- **Complexidade**: Média

### Task 6: Verificação pós-implementação (Prioridade: BAIXA)

- **Descrição**: Testar que agentes conseguem ler e interpretar AGENTS.md (executar tarefa simples com dev agent)
- **Acceptance**: Agente dev consegue ler AGENTS.md e criar arquivo `.opencode/test.md` com conteúdo 'test' via comando bash
- **Verify**: Executar `cat .opencode/test.md` e verificar conteúdo 'test'; verificar que agente não errou
- **Files**: `AGENTS.md`
- **Complexidade**: Baixa
- **Status**: ✅ Concluído em [30/06/2026:09:08]

### Task 7: Verificar coerência com MULTI_AGENT_ORCHESTRATION.md (Prioridade: MÉDIA)

- **Descrição**: Verificar se há informações duplicadas ou inconsistentes entre AGENTS.md e MULTI_AGENT_ORCHESTRATION.md. Incluir verificação de overlap de "Anti-padrões" (seção "Anti-padrões", linhas 293-299 do AGENTS.md vs linhas 802-806 do MULTI_AGENT_ORCHESTRATION.md).
- **Acceptance**: Documentação consistente entre os dois arquivos, sem duplicidades
- **Verify**: Comparar seções relevantes e documentar divergências encontradas
- **Files**: `AGENTS.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`
- **Complexidade**: Média
- **Status**: ✅ Concluído em [30/06/2026:08:24]

## Dependências

- **Pré-requisitos**: Acesso ao AGENTS.md e MULTI_AGENT_ORCHESTRATION.md
- **Ordem**: Tasks podem ser executadas em paralelo (são independentes), exceto a ordem de implementação definida abaixo

## Riscos

- **Risco**: Remover informação importante → **Mitigação**: Verificar MULTI_AGENT_ORCHESTRATION.md antes de remover
- **Risco**: Quebrar referências → **Mitigação**: Testar carregamento do AGENTS.md após alterações

## Ordem de Implementação

1. Task 5 (RBAC) - ALTA prioridade (mais crítico)
2. Task 1 (remover duplicidade) - ALTA prioridade
3. Task 2 (simplificar melhorias) - MÉDIA prioridade
4. Task 7 (verificar coerência) - MÉDIA prioridade
5. Task 3 (loop de trabalho) - MÉDIA prioridade
6. Task 4 (regras de delegação) - MÉDIA prioridade
7. Task 6 (validação pós-implementação) - BAIXA prioridade (executar após todas as outras)

## Verificação Final

1. Contar linhas do AGENTS.md antes/depois (esperado: redução de ~30 linhas)
2. Verificar que todas as referências a documentos externos estão corretas
3. Testar que agentes ainda conseguem ler e interpretar o AGENTS.md
4. Verificar que MULTI_AGENT_ORCHESTRATION.md contém todas as informações detalhadas

## Resumo das Mudanças Esperadas

| Seção | Linhas Atuais | Ação | Linhas Esperadas |
|-------|---------------|------|------------------|
| Referências Doc por Fluxo | 282-291 | Remover | 0 |
| Melhorias Recentes | 301-314 | Simplificar | 3-4 |
| RBAC (linhas 149-152, 211, 306) | 149-152, 211, 306 | Comparar e corrigir | Manter/ajustar |
| Loop de trabalho | 258-276 | Comparar e decidir | Manter/ajustar |
| Regras de delegação | 238-244 | Comparar e remover duplicações | Manter/ajustar |
| Verificação pós-implementação | Nova task | Adicionar | 0 |
| Coerência com MULTI_AGENT_ORCHESTRATION.md | Nova task | Adicionar | 0 |
| **Total** | 331 | Reduzir | ~300 |
