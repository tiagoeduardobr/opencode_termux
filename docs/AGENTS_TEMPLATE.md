# {PROJECT_NAME} — Guia para Agentes de IA

> **IMPORTANTE**: Os agentes e skills já estão disponíveis via symlink global.
> NUNCA copie os prompts .md dos agentes ou diretórios de skills para este projeto.
> Apenas crie este AGENTS.md com as convenções específicas deste projeto.

{PROJECT_DESCRIPTION}

<!-- ============================================================
     INSTRUÇÕES: Preencha os placeholders acima.
     - {PROJECT_NAME}: nome do projeto (ex: "parecer_descritivo", "meu-app")
     - {PROJECT_DESCRIPTION}: uma frase descrevendo o projeto
     ============================================================ -->

## Estrutura do Projeto

```
{PROJECT_ROOT}/
├── {SOURCE_DIR}/                  ← código fonte
│   └── ...
├── {TEST_DIR}/                    ← testes
│   └── ...
├── docs/                          ← documentação
│   └── ...
├── opencode.json                  ← config do projeto
├── AGENTS.md                      ← este arquivo
└── README.md
```

<!-- ============================================================
     INSTRUÇÕES: Adapte a estrutura acima ao layout real do projeto.
     Inclua apenas os diretórios relevantes. Mantenha a árvore enxuta.
     ============================================================ -->

## Skills e Subagentes Disponíveis

Este projeto usa 5 agentes e 40 skills via symlink `~/.config/opencode/` → `opencode_termux/.config/opencode/`.
As skills estão em 3 diretórios (todos via symlink global):

- `~/.config/opencode/skills/` — skills globais
- `.opencode/skills/` — skills específicas do projeto
- `.agents/skills/` — skills de agentes customizados

**Subagentes**:
| Agente | Função |
|--------|--------|
| `task-build` | Orquestra pipeline completo (planejar → implementar → revisar → commitar) |
| `task-planner` | Cria planos adaptativos antes de implementar |
| `dev` | Implementa código seguindo o plano |
| `code-review` | Revisa qualidade, segurança e conformidade |
| `git-commit` | Gerencia branches, commits semânticos e cleanup |

> **Nota**: `explore` e `compaction` são agentes built-in do OpenCode, NÃO
> configuráveis via `opencode.json`.

**Skills obrigatórias por agente**:

| Agente | Skills obrigatórias |
|--------|---------------------|
| `task-build` | `executing-plans` |
| `task-planner` | `spec-driven-development`, `executing-plans` |
| `dev` | `executing-plans`, `systematic-debugging` |
| `code-review` | `api-security-best-practices`, `staff-engineer-review`, `code-reviewer`, `agent-restrictions` |
| `git-commit` | nenhuma |

<!-- ============================================================
     INSTRUÇÕES: Adicione skills específicas do projeto se houver.
     Exemplo: "fastapi-expert" se o projeto usa FastAPI.
     Lista completa: ~/.config/opencode/skills/
     ============================================================ -->

## Convenções do Projeto

### Código

- **Linguagem**: {LANGUAGE}
- **Framework**: {FRAMEWORK}
- **Formatter**: {FORMATTER} (ex: black, prettier, gofmt)
- **Linter**: {LINTER} (ex: ruff, eslint, golangci-lint)
- **Naming**: {NAMING_CONVENTION} (ex: snake_case para Python, camelCase para JS)

<!-- ============================================================
     INSTRUÇÕES: Preencha com as convenções reais do projeto.
     Inclua exemplos de código se útil.
     ============================================================ -->

### Quality Checks

Quality checks são auto-detectados pelo `code-review` e `dev`:
- Python: `ruff format --check`, `ruff check`, `pytest`
- Node.js: `npm run build`, `npm run lint`, `npm test`
- Makefile: `make lint`, `make test`, `make build`

<!-- ============================================================
     INSTRUÇÕES: Adapte os comandos de quality check ao projeto.
     Se o projeto não se encaixa nas categorias acima, defina manualmente.
     ============================================================ -->

### Commits

- **Formato**: `{TYPE}({SCOPE}): {description}` (Conventional Commits)
- **Tipos permitidos**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- **Idioma**: inglês (sempre)
- **Exemplo**: `feat(auth): add JWT validation middleware`

### Estrutura de Testes

- **Framework**: {TEST_FRAMEWORK} (ex: pytest, jest, go test)
- **Localização**: {TEST_LOCATION} (ex: `tests/`, `__tests__/`, `*_test.go`)
- **Cobertura mínima**: {COVERAGE_THRESHOLD}% (se aplicável)

<!-- ============================================================
     INSTRUÇÕES: Defina onde os testes ficam e qual framework usar.
     ============================================================ -->

### Branches

- **Padrão**: `feature/TODO-{CAT}-{NUM}-{slug}` para features
- **Fix**: `fix/TODO-{CAT}-{NUM}-{slug}` para correções
- **Main**: `main` (ou `master` — confirmar)

### Backlog

- **Arquivo**: `docs/PROJECT_BACKLOG_{PROJECT_NAME}.md`
- **Formato**: `- [ ] **TODO-{CAT}-{NN}:** Descrição`
- **Conclusão**: `- [x] **TODO-{CAT}-{NN}:** Descrição – Concluído em [DD/MM/YYYY:HH:MM]`

> **IMPORTANTE**: O timestamp deve ser gerado via `date '+%d/%m/%Y:%H:%M'` —
> nunca digitado manualmente.

## Agent Workflow — Orquestração

> **Documentação completa**: Para deep-dive na orquestração, RBAC,
> mecanismos de robustez e gotchas, veja `docs/MULTI_AGENT_ORCHESTRATION.md`.

### Qual agente usar

| Tarefa | Agente | Quando usar |
|--------|--------|-------------|
| Explorar codebase rápido | `explore` | Buscar arquivos, entender estrutura, achar padrões |
| Planejar tarefa antes de implementar | `task-planner` | Gerar plano adaptativo com escopo, dependências e riscos |
| Implementar código | `dev` | Executar tasks do plano com qualidade e conformidade |
| Orquestrar entrega completa | `task-build` | Pipeline completo: planejar → implementar → revisar → commitar |
| Mudanças simples (1-3 arquivos) | `dev` | Edits, fixes, refactors pontuais |
| Mudanças complexas (3+ arquivos) | `task-build` ou `task-planner` → `dev` → `code-review` | Planejar → implementar → revisar |
| Criar commit | `git-commit` | Sempre após mudanças aprovadas (inclui branch e cleanup) |
| Revisão de PR/code | `code-review` | Após implementação, antes de merge |
| Criar skill ou agent | `customize-opencode` | Seguir template do opencode |
| Tarefa com plano escrito | `executing-plans` | Re-executar planos com checkpoints |

> **RBAC**: agentes inferiores (`dev`, `code-review`, `task-planner`, `git-commit`)
> são isolados — cada um nega todos os outros subagentes. Apenas `task-build` pode chamá-los.

### Padrões de orquestração

**Padrão simples** (mudança pontual):
```
1. explore → entender contexto
2. dev → implementar
3. git-commit → branch + commit + cleanup
```

**Padrão completo** (feature ou fix complexo):
```
1. task-build → ler AGENTS.md + receber tarefa
2. task-planner → gerar plano adaptativo
3. dev → implementar
4. code-review → revisar qualidade (individual + consolidado)
5. git-commit → branch + commit + cleanup
```

**Padrão de revisão** (após receber PR/issues):
```
1. code-review → analisar mudanças
2. dev → aplicar feedback
3. git-commit → commitar fixes
```

### Regras de delegação

1. **Nunca duplique trabalho** — se delegou para um agente, aguarde o resultado
2. **Encadeie agentes** — passe o resultado de um como contexto do próximo
3. **Use task_id** — para continuar sessão anterior, passe o task_id
4. **Skills primeiro** — antes de implementar, verifique se há skill relevante
5. **Docs antes de código** — sempre leia `docs/` relevante antes de modificar código

### Loop de trabalho

```
┌─────────────────────────────────────────────────┐
│  0. Ler AGENTS.md                               │
│     └─ entender convenções e gotchas             │
│  1. Entender tarefa                              │
│     └─ explore ou ler contexto                   │
│  2. Planejar (se complexo)                       │
│     └─ task-planner agent                        │
│  3. Implementar                                  │
│     └─ dev agent                                 │
│  4. Verificar                                    │
│     └─ code-review (individual por task)         │
│  5. Revisão consolidada                          │
│     └─ code-review (todas as tasks)              │
│  6. Commitar + Push                              │
│     └─ git-commit agent                          │
└─────────────────────────────────────────────────┘

Ou usar o agente `task-build` para orquestrar tudo automaticamente.
```

> **Regra**: Code review é OBRIGATÓRIO antes de CADA commit (individual + consolidado).
> task-build NUNCA edita arquivos — todas as mudanças são delegadas para dev.

### Anti-padrões

> **Anti-padrões gerais**: Veja `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 9.2)
> para a lista completa de anti-padrões do sistema multi-agente.

<!-- ============================================================
     INSTRUÇÕES: Adicione anti-padrões ESPECÍFICOS deste projeto abaixo.
     Exemplo: ❌ "Não usar ORM raw" se o projeto usa SQLAlchemy.
     ============================================================ -->

- **{ANTI_PATTERN_1_TITLE}**: {ANTI_PATTERN_1_DESCRIPTION}
- **{ANTI_PATTERN_2_TITLE}**: {ANTI_PATTERN_2_DESCRIPTION}

## Gotchas deste Projeto

- **RBAC syntax**: O formato correto é `"agente": "perm"`, não `"perm": ["agente"]`.
  O formato array é silenciosamente ignorado pelo OpenCode.

<!-- ============================================================
     INSTRUÇÕES: Liste armadilhas conhecidas deste projeto específico.
     Adicione mais gotchas específicas do projeto abaixo.
     ============================================================ -->

- **{GOTCHA_1_TITLE}**: {GOTCHA_1_DESCRIPTION}
- **{GOTCHA_2_TITLE}**: {GOTCHA_2_DESCRIPTION}
- **{GOTCHA_3_TITLE}**: {GOTCHA_3_DESCRIPTION}

## Comandos Úteis

```bash
# Build
{BUILD_COMMAND}

# Test
{TEST_COMMAND}

# Lint
{LINT_COMMAND}

# Dev server
{DEV_COMMAND}
```

<!-- ============================================================
     INSTRUÇÕES: Substitua pelos comandos reais do projeto.
     Inclua flags relevantes (ex: --coverage, --fix).
     ============================================================ -->

## Leitura Recomendada por Tarefa

| Tarefa | Docs para ler |
|--------|---------------|
| **Setup do projeto** | {SETUP_DOCS} |
| **Debug** | {DEBUG_DOCS} |
| **Deploy** | {DEPLOY_DOCS} |

<!-- ============================================================
     INSTRUÇÕES: Mapeie tarefas comuns para os documentos relevantes.
     ============================================================ -->

## Notas de Implementação

1. **Seção "Gotchas"**: Esta é a seção mais valiosa para agentes. Liste
   tudo que um dev humano precisaria saber para não quebrar o projeto.

2. **Referência externa**: O AGENTS.md aponta para `MULTI_AGENT_ORCHESTRATION.md`
   para deep-dive. Não duplique a documentação de RBAC, circuit breaker, etc.

3. **Versão**: Adicione `> **Versão**: {DATE}` no topo do AGENTS.md para
   rastrear atualizações.
