# Plano: Corrigir agentes (hidden/color) e documentação pós-migração 1.18.1

## Objetivo

Corrigir configurações dos 4 subagentes que ficaram incorretas após a migração para OpenCode 1.18.1 (commit c08a93e), e atualizar documentação para refletir o estado real do sistema (permission.task não funciona no frontmatter .md).

## Escopo

- Dentro: Modificar `hidden` e `color` nos 4 subagentes; corrigir docs (MULTI_AGENT_ORCHESTRATION.md, AGENTS.md)
- Fora: NÃO adicionar `permission.task: []` de volta; NÃO modificar scripts Termux/proot; NÃO modificar opencode.json

## Assumptions

1. O parser YAML do OpenCode 1.18.1 NÃO suporta `permission.task` no frontmatter .md — confirmado pelo usuário
2. `hidden: true` esconde agentes do TUI — queremos todos visíveis (exceto task-build que já está `hidden: false`)
3. Cores: task-build=blue, task-planner=green, dev=orange, code-review=purple, git-commit=gray
4. O plano anterior `20260715_1200_yaml-frontmatter-gotchas.md` é parcialmente substituído por este (mantém-se como contexto histórico)
5. `git-commit.md` deveria ter `color: "#808080"` (cinza) conforme planejado na migração, mas ficou com `"#9D00FF"` (roxo) por erro

## Dependências

- Pré-requisitos: Nenhum
- Ordem: Agentes primeiro (independentes entre si) → Docs → Verificação

## Tasks

- [ ] Task 1: Alterar `hidden: true` → `hidden: false` nos 4 subagentes
  - Acceptance: Todos os 4 arquivos (.md) de subagentes têm `hidden: false` no frontmatter YAML
  - Verify: `grep "hidden:" .config/opencode/agents/*.md` mostra `hidden: false` em 4 arquivos e `hidden: false` em task-build (5 total)
  - Files: `.config/opencode/agents/task-planner.md`, `.config/opencode/agents/dev.md`, `.config/opencode/agents/code-review.md`, `.config/opencode/agents/git-commit.md`
  - Complexidade: Baixa

  **Mudanças específicas:**
  - `task-planner.md` linha 4: `hidden: true` → `hidden: false`
  - `dev.md` linha 4: `hidden: true` → `hidden: false`
  - `code-review.md` linha 4: `hidden: true` → `hidden: false`
  - `git-commit.md` linha 4: `hidden: true` → `hidden: false`

- [ ] Task 2: Corrigir cor do git-commit.md de roxo para cinza
  - Acceptance: `git-commit.md` tem `color: "#808080"` no frontmatter
  - Verify: `grep 'color:' .config/opencode/agents/git-commit.md` mostra `"#808080"`
  - Files: `.config/opencode/agents/git-commit.md`
  - Complexidade: Baixa

  **Mudança específica:**
  - `git-commit.md` linha 5: `color: "#9D00FF"` → `color: "#808080"`

- [ ] Task 3: Atualizar seção 4.3 de MULTI_AGENT_ORCHESTRATION.md — remover `task` de campos do frontmatter
  - Acceptance: A linha que lista `task` como campo de permissão no frontmatter é removida ou corrigida com nota de que não funciona no .md
  - Verify: `grep -n "permission" docs/MULTI_AGENT_ORCHESTRATION.md | grep -i "task"` não retorna resultado na seção 4.3 (linhas ~218-226)
  - Files: `docs/MULTI_AGENT_ORCHESTRATION.md`
  - Complexidade: Baixa

  **Mudança específica (linha 224):**
  - De: `- Permissões no frontmatter: bash (patterns), read, edit, write, question, skill, task`
  - Para: `- Permissões no frontmatter: bash (patterns), read, glob, grep, edit, write, question, skill`
  - Nota: `task` NÃO é suportado no frontmatter .md — ver seção 9.6.3

  **Também atualizar linha 225:**
  - De: `- hidden: true para subagentes, hidden: false para primary`
  - Para: `- hidden: false para todos os agentes (visíveis no TUI)`

- [ ] Task 4: Atualizar seção 8.2 template de agente subagent — remover `task: []`
  - Acceptance: O template YAML na seção 8.2 NÃO contém `task: []`
  - Verify: `sed -n '485,505p' docs/MULTI_AGENT_ORCHESTRATION.md` não mostra `task: []`
  - Files: `docs/MULTI_AGENT_ORCHESTRATION.md`
  - Complexidade: Baixa

  **Mudança específica (linha 503):**
  - Remover a linha `  task: []` do template YAML
  - O template ficará com permission contendo apenas: bash, read, glob, grep, edit, write, question, skill
  - Adicionar nota abaixo do template: `> **NOTA**: `permission.task` NÃO é suportado no frontmatter .md (ver seção 9.6.3)`

- [ ] Task 5: Atualizar seção 9.1 Erros Comuns — adicionar entrada YAML
  - Acceptance: Tabela de erros comuns contém entrada sobre YAML frontmatter
  - Verify: `grep "YAML" docs/MULTI_AGENT_ORCHESTRATION.md` retorna resultado na seção 9.1
  - Files: `docs/MULTI_AGENT_ORCHESTRATION.md`
  - Complexidade: Baixa

  **Entrada a adicionar na tabela 9.1 (após linha ~624):**

  | YAML frontmatter mal formatado | Ver seção 9.6 — hex colors, `*`, `permission.task`, validação, delimitadores |

- [ ] Task 6: Adicionar NOVA seção 9.6 YAML Frontmatter Gotchas
  - Acceptance: Seção 9.6 inserida com 5 subseções (9.6.1-9.6.5) entre seção 9.5 e seção 10
  - Verify: `grep -c "9.6" docs/MULTI_AGENT_ORCHESTRATION.md` retorna >= 6 (título + 5 subseções)
  - Files: `docs/MULTI_AGENT_ORCHESTRATION.md`
  - Complexidade: Baixa

  **Conteúdo a inserir (APÓS linha ~683, ANTES de `## 10. Melhorias Recentes`):**

  ```markdown
  ### 9.6 YAML Frontmatter Gotchas

  > **Lição aprendida em 15/07/2026**: Edição manual dos frontmatters dos agentes
  > causou quebras no OpenCode 1.18.1. Estas são as armadilhas conhecidas.

  #### 9.6.1 Hex colors precisam de aspas

  | Correto | Incorreto | Problema |
  |---------|-----------|----------|
  | `color: "#FFA500"` | `color: #FFA500` | `#` é início de comentário YAML — valor fica null |

  **Regra**: Qualquer cor hex DEVE estar entre aspas duplas: `color: "#HEXCODE"`.

  #### 9.6.2 `*` é alias YAML — usar aspas na chave

  | Correto | Incorreto | Problema |
  |---------|-----------|----------|
  | `"*": allow` | `*: allow` | YAML tenta resolver como alias de referência |

  **Regra**: Chaves com `*` DEVIEM ter aspas: `"*": allow`, `"git *": deny`.

  #### 9.6.3 `permission.task` NÃO funciona no frontmatter .md

  | Campo | Suportado no frontmatter .md | Suportado no opencode.json |
  |-------|-----|-----|
  | `permission.bash` | ✅ Sim | ✅ Sim |
  | `permission.read` | ✅ Sim | ✅ Sim |
  | `permission.edit` | ✅ Sim | ✅ Sim |
  | `permission.write` | ✅ Sim | ✅ Sim |
  | `permission.skill` | ✅ Sim | ✅ Sim |
  | `permission.question` | ✅ Sim | ✅ Sim |
  | **`permission.task`** | **❌ Não** | **✅ Sim** |

  **Problema**: O parser YAML do OpenCode 1.18.1 ignora `task` dentro de `permission:` no frontmatter .md.
  Subagentes sem `permission.task` ficam com acesso ilimitado a outros subagentes.

  **Workaround**: Configurar `permission.task` no `opencode.json` do projeto (seção `"agent"`),
  não no frontmatter .md. Ou aceitar que subagentes podem chamar outros subagentes.

  **Nota**: Este é um bug/conhecido do OpenCode 1.18.1. Pode ser corrigido em versões futuras.

  #### 9.6.4 Validar YAML antes de aplicar

  Sempre validar o frontmatter YAML após edição:

  ```bash
  # Validar frontmatter de um agente
  python3 -c "
  import yaml
  content = open('.config/opencode/agents/nome-agente.md').read()
  fm = content.split('---')[1]
  yaml.safe_load(fm)
  print('YAML válido')
  "

  # Validar TODOS os agentes de uma vez
  for f in .config/opencode/agents/*.md; do
    python3 -c "
  import yaml
  content = open('$f').read()
  fm = content.split('---')[1]
  yaml.safe_load(fm)
  print('$f: OK')
  " 2>&1 || echo "$f: FALHA"
  done
  ```

  **Alternativa**: `opencode debug agent <name>` para verificar parsing pelo OpenCode.

  #### 9.6.5 Delimitadores `---` no body do markdown

  | Correto | Incorreto | Problema |
  |---------|-----------|----------|
  | `### Seção` | `---` (isolado no body) | Parsers YAML ingênuos interpretam como fim do frontmatter |

  **Regra**: O body do markdown NÃO deve conter `---` isolados como separadores de seção.
  Usar `###` ou `####` em vez disso. O parser do OpenCode é robusto, mas parsers YAML
  genéricos (como `python3 -c "import yaml; ..."`) podem falhar.
  ```

- [ ] Task 7: Atualizar AGENTS.md — corrigir referências a `permission.task` no frontmatter
  - Acceptance: As seções relevantes do AGENTS.md refletem que `permission.task` não funciona no frontmatter .md
  - Verify: `grep -n "permission.task" AGENTS.md` mostra notas de warning onde apropriado
  - Files: `AGENTS.md`
  - Complexidade: Baixa

  **Mudanças específicas:**

  **Linhas 165-177** (seção Convenções e Gotchas — permission.task):
  - Manter a documentação sobre `permission.task` mas adicionar warning:
  - Após linha 172 (bloco yaml `task: []`), adicionar:
    ```
    > **⚠️ WARN**: `permission.task` NÃO é suportado no frontmatter .md dos agentes.
    > O parser do OpenCode 1.18.1 ignora este campo em arquivos .md.
    > Para configurar isolamento de subagentes, use `opencode.json` do projeto (seção `"agent"`).
    > Ver seção 9.6.3 de `docs/MULTI_AGENT_ORCHESTRATION.md` para detalhes.
    ```

  **Linha 232** (seção Agent Workflow):
  - De: `> **Isolamento**: agentes inferiores (`dev`, `code-review`, `task-planner`, `git-commit`) são isolados via `permission.task: []`. Apenas `task-build` (primary) pode chamá-los.`
  - Para: `> **Isolamento**: Subagentes NÃO possuem `permission.task: []` no frontmatter (não suportado pelo parser). Todos podem chamar outros subagentes. Para restringir, configurar no `opencode.json` do projeto.`

- [ ] Task 8: Verificação final de consistência
  - Acceptance:
    - Todos os 4 subagentes têm `hidden: false`
    - `git-commit.md` tem `color: "#808080"`
    - `task-build.md` mantém `hidden: false` (inalterado)
    - Nenhum agente tem `task: []` no frontmatter
    - Seção 9.6 existe com 5 subseções
    - Tabela 9.1 tem entrada YAML
    - Seção 8.2 template não tem `task: []`
    - AGENTS.md tem warnings sobre `permission.task` no .md
  - Verify:
    - `grep "hidden:" .config/opencode/agents/*.md` — todos mostram `hidden: false`
    - `grep 'color:' .config/opencode/agents/git-commit.md` — mostra `"#808080"`
    - `grep -c "task:" .config/opencode/agents/*.md` — nenhum resultado com `task: []`
    - `grep -c "9.6" docs/MULTI_AGENT_ORCHESTRATION.md` — >= 6
    - `grep "YAML" docs/MULTI_AGENT_ORCHESTRATION.md` — resultado na seção 9.1
    - `python3 -c "import yaml; yaml.safe_load(open('.config/opencode/agents/' + f).read().split('---')[1])"` para cada agente — todos OK
  - Files: Todos os arquivos (leitura apenas)
  - Complexidade: Baixa

## Riscos

| Risco | Mitigação |
|-------|-----------|
| `hidden: false` em subagentes pode poluir TUI | task-build continua primary — subagentes aparecem apenas via @mention, não na aba principal |
| `permission.task` ausente permite subagentes chamarem outros | Documentar como workaround via opencode.json; accept risk para pipeline atual |
| Seção 9.6 inserida em ponto errado | Verificar linha da seção 10 (atualmente ~685) antes de inserir |

## Ordem de Implementação

1. Task 1 (hidden nos 4 subagentes) — paralelizável com Task 2
2. Task 2 (cor git-commit) — paralelizável com Task 1
3. Task 3 (seção 4.3 docs)
4. Task 4 (seção 8.2 template)
5. Task 5 (seção 9.1 erros comuns)
6. Task 6 (nova seção 9.6)
7. Task 7 (AGENTS.md warnings)
8. Task 8 (verificação final)

## Verificação Final

- [ ] Todos os 4 subagentes com `hidden: false`
- [ ] `git-commit.md` com `color: "#808080"` (cinza)
- [ ] Nenhum agente com `task: []` no frontmatter
- [ ] Seção 9.6 YAML Frontmatter Gotchas existe com 5 subseções
- [ ] Tabela 9.1 tem entrada referenciando 9.6
- [ ] Seção 8.2 template não contém `task: []`
- [ ] AGENTS.md tem warnings sobre `permission.task` no .md
- [ ] Todos os frontmatters YAML validam (python3 yaml.safe_load)
- [ ] Plano anterior `20260715_1200_yaml-frontmatter-gotchas.md` não conflita (mantido como contexto)

## Nota sobre plano anterior

O plano `20260715_1200_yaml-frontmatter-gotchas.md` cobria APENAS a documentação (seção 9.6).
Este plano é mais completo: inclui as correções nos arquivos de agentes (hidden, color) E a
documentação. O plano anterior pode ser considerado obsoleto após a execução deste.
