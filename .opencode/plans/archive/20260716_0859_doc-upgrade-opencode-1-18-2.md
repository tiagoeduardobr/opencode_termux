# Plano: Documentar upgrade OpenCode 1.18.1 → 1.18.2

## Objetivo

Atualizar toda a documentação do repositório `opencode_termux` para refletir o
upgrade de OpenCode 1.18.1 para 1.18.2. A mudança central do 1.18.2 — subagentes
não lançam subagentes aninhados por padrão (`subagent_depth`) — impacta
diretamente a documentação de isolamento de agentes (permission.task).

**package.json e package-lock.json já estão atualizados** (`^1.18.2` / `1.18.2`).
Este plano cobre APENAS documentação.

## Escopo

- **Dentro**: Atualização de referências 1.18.1→1.18.2, novas notas sobre
  `subagent_depth`, entrada de sessão, verificação de coerência
- **Fora**: Modificação de agentes .md, scripts, opencode.json, código

## Assumptions

1. O plugin `@opencode-ai/plugin` 1.18.2 já está instalado e funcional (package.json já aponta para `^1.18.2`)
2. A mudança `subagent_depth` é o único behavioral change relevante no 1.18.2
3. `permission.task` continua funcionando em `opencode.json` (não há regressão)
4. O parser YAML do frontmatter .md continua ignorando `permission.task` (bug não corrigido no 1.18.2)
5. Os built-in agents (Build, Plan, General, Explore, Scout) não tiveram mudanças de interface

## Dependências

- **Pré-requisitos**: package.json e package-lock.json já atualizados (confirmado)
- **Ordem**: Tasks 1→5 (sequencial por dependência de contexto)

## Tasks

### Task 1: Atualizar MULTI_AGENT_ORCHESTRATION.md — Cabeçalho e versão

Atualizar a linha de "Última atualização" e "Versão do sistema" no cabeçalho.

- **Acceptance**: Cabeçalho reflete data de hoje e versão 1.18.2
- **Verify**: `grep "1.18.2" docs/MULTI_AGENT_ORCHESTRATION.md` retorna matches
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md`
- **Complexidade**: Baixa
- **Alterações**:
  - Linha 3: `> **Última atualização**: 2026-06-30` → `> **Última atualização**: 2026-07-16`
  - Linha 4: `> **Versão do sistema**: 5 agentes + 50 skills` → `> **Versão do sistema**: 5 agentes + 50 skills + OpenCode 1.18.2`

### Task 2: Atualizar MULTI_AGENT_ORCHESTRATION.md — Seção 5 (permission.task)

Reescrever tom da seção para refletir que 1.18.2 torna `permission.task` menos
crítico, mas ainda funcional. Adicionar nota sobre `subagent_depth`.

- **Acceptance**: Seção 5 menciona 1.18.2, `subagent_depth`, e o tom reflete que isolamento agora é default
- **Verify**: `grep "1.18.2" docs/MULTI_AGENT_ORCHESTRATION.md` retorna matches na seção 5
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md`
- **Complexidade**: Média
- **Alterações**:
  - Linha 326: `O OpenCode 1.18.1 usa permission.task` → `O OpenCode 1.18.2 usa permission.task` (manter 1.18.1 como referência histórica se necessário)
  - Linhas 348-350 (WARN sobre permission.task não funcionar no frontmatter): Adicionar nota de que no 1.18.2 subagentes já são isolados por padrão via `subagent_depth`
  - Linha 360: Atualizar referência para 1.18.2
  - Linha 385: Atualizar referência para 1.18.2
  - NOVO parágrafo após 5.3: Nota sobre `subagent_depth` no 1.18.2

### Task 3: Atualizar MULTI_AGENT_ORCHESTRATION.md — Seção 9.6.3 e 10

Atualizar a seção 9.6.3 (permission.task no frontmatter) e adicionar nota sobre
1.18.2. Adicionar entrada na seção 10 (Melhorias Recentes).

- **Acceptance**: Seção 9.6.3 tem NOTA sobre 1.18.2/subagent_depth; seção 10 tem entrada 1.18.2
- **Verify**: `grep "subagent_depth" docs/MULTI_AGENT_ORCHESTRATION.md` retorna match
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md`
- **Complexidade**: Média
- **Alterações**:
  - Linha 701: `OpenCode 1.18.1` → `OpenCode 1.18.2`
  - Linha 732: `O parser YAML do OpenCode 1.18.1 ignora` → `O parser YAML do OpenCode 1.18.2 ignora`
  - Linhas 734-735 (Workaround): Adicionar nota de que no 1.18.2 o workaround tornou-se menos necessário pois subagentes já são isolados por padrão (`subagent_depth`)
  - Linha 777: Adicionar `subagent_depth` à lista de melhorias recentes
  - Linha 823: `Agentes Built-in do OpenCode 1.18.1` → `Agentes Built-in do OpenCode 1.18.2`
  - Linha 825: `O OpenCode 1.18.1 inclui` → `O OpenCode 1.18.2 inclui`

### Task 4: Atualizar AGENTS.md

Atualizar referências 1.18.1→1.18.2 e adicionar nota sobre isolamento default no 1.18.2.

- **Acceptance**: AGENTS.md referencia 1.18.2, tem nota sobre subagent_depth
- **Verify**: `grep "1.18.2" AGENTS.md` retorna matches
- **Files**: `AGENTS.md`
- **Complexidade**: Média
- **Alterações**:
  - Linha 165: `(OpenCode 1.18.1)` → `(OpenCode 1.18.2)` — ou adicionar nota
  - Linha 169: `O parser do OpenCode 1.18.1 ignora` → `O parser do OpenCode 1.18.2 ignora`
  - Linha 238: Atualizar referência para 1.18.2
  - Linha 285: Adicionar nova entrada `Atualização para OpenCode 1.18.2: subagentes isolados por padrão (subagent_depth)` logo abaixo da entrada 1.18.1

### Task 5: Adicionar entrada de sessão em SESSION_CONTEXT_20260618.md

Adicionar seção documentando a atualização 1.18.2.

- **Acceptance**: Nova seção no SESSION_CONTEXT com data, versão, mudanças e arquivos afetados
- **Verify**: `grep "1.18.2" docs/SESSION_CONTEXT_20260618.md` retorna match
- **Files**: `docs/SESSION_CONTEXT_20260618.md`
- **Complexidade**: Baixa
- **Alterações**:
  - Após linha 270 (final do arquivo), adicionar nova seção:
    ```
    ### Atualização OpenCode 1.18.2 (16/07/2026)

    **O que foi feito**:
    - Atualização de OpenCode 1.18.1 para 1.18.2 (CLI + plugin)
    - Mudança principal: subagentes não lançam subagentes aninhados por padrão (`subagent_depth`)
    - `permission.task` menos crítico: isolamento agora é default

    **Arquivos modificados**:
    - `.config/opencode/package.json` (plugin ^1.18.0 → ^1.18.2)
    - `.config/opencode/package-lock.json` (atualizado pelo npm install)
    - `AGENTS.md` (referências 1.18.1→1.18.2, nota subagent_depth)
    - `docs/MULTI_AGENT_ORCHESTRATION.md` (seções 5, 9.6.3, 10, 11.4)
    - `docs/SESSION_CONTEXT_20260618.md` (esta entrada)

    **Skills**: 50 (inalterado)
    **Agentes**: 5 (inalterado)
    ```

### Task 6: Verificação final de coerência

Verificar que todas as referências estão consistentes e não há menções obsoletas.

- **Acceptance**: Todos os `grep "1.18.1"` em docs apontam para contexto histórico correto; nenhum `1.18.1` isolado indica versão atual
- **Verify**: Comandos de verificação abaixo
- **Files**: Todos os arquivos da task (somente leitura)
- **Complexidade**: Baixa
- **Comandos de verificação**:
  ```bash
  # Verificar que package.json aponta para 1.18.2
  grep "1.18.2" .config/opencode/package.json

  # Verificar referências em AGENTS.md
  grep -n "1.18" AGENTS.md

  # Verificar referências em MULTI_AGENT_ORCHESTRATION.md
  grep -n "1.18" docs/MULTI_AGENT_ORCHESTRATION.md

  # Verificar referências em SESSION_CONTEXT
  grep -n "1.18" docs/SESSION_CONTEXT_20260618.md

  # Verificar que não há "1.18.1" isolado como versão atual
  # (1.18.1 pode aparecer em contexto histórico, mas não como versão vigente)
  grep -n "1.18.1" AGENTS.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md
  ```

## Riscos

- **Risco 1**: Referências 1.18.1 ficam ambíguas (histórica vs. atual) → Mitigação: sempre que 1.18.1 aparecer em contexto de "versão atual", atualizar para 1.18.2; quando em contexto histórico (ex: "Migração para 1.18.1"), manter
- **Risco 2**: `subagent_depth` pode ter parâmetros específicos não documentados → Mitigação: documentar apenas o conceito (default=0) sem assumir valores específicos sem confirmação

## Ordem de Implementação

1. Task 1 (cabeçalho) — prerequisite para tasks seguintes (atualiza data)
2. Task 2 (seção 5) — prerequisite para Task 3 (contexto de permission.task)
3. Task 3 (seções 9.6.3 + 10) — depende de Task 2
4. Task 4 (AGENTS.md) — independente, mas fazer após Tasks 1-3 para coerência
5. Task 5 (SESSION_CONTEXT) — independente, mas fazer após outras para listar todos os arquivos
6. Task 6 (verificação) — última, depende de todas as anteriores

## Verificação Final

Após todas as tasks:
1. `grep -rn "1.18.2" AGENTS.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md .config/opencode/package.json` — deve retornar matches em todos
2. `grep -rn "subagent_depth" docs/MULTI_AGENT_ORCHESTRATION.md AGENTS.md` — deve retornar matches
3. Nenhuma referência a "1.18.1" isolada como versão vigente (apenas em contexto histórico)
4. `git diff --stat` mostra apenas 3 arquivos modificados: `AGENTS.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`, `docs/SESSION_CONTEXT_20260618.md`
