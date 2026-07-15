# Plano: Adaptação do opencode_termux ao OpenCode 1.18.1

## Objetivo

Migrar a configuração de agentes do opencode_termux para o formato OpenCode 1.18.1,
aproveitando features nativas (`permission.task`, markdown agents puros, `hidden`,
`color`, `steps`) e eliminando workarounds customizados (`rbac` no JSON). O sistema
de 5 agentes orquestrados será preservado com o mesmo comportamento, mas usando o
formato oficial do 1.18.1.

## Escopo

- **Dentro**: Migrar agentes de JSON para markdown puro, substituir `rbac` por
  `permission.task`, adicionar `hidden`/`color`/`steps`, atualizar docs e dependências
- **Fora**: Modificar o comportamento dos agentes (workflows, prompts), criar novos
  agentes, alterar o sistema de skills, modificar scripts Termux/proot

## Assumptions

1. OpenCode 1.18.1 está instalado ou será instalado antes da migração
2. O campo `mode` no frontmatter markdown é aceito pelo 1.18.1 (já usado nos .md atuais)
3. `permission.task` aceita o formato `"agente": ["agente1", "agente2"]` ou similar
4. Agentes markdown em `.config/opencode/agents/` são auto-descobertos (sem referência `{file:...}`)
5. O `{file:...}` no JSON continua funcionando para backward compatibility
6. A seção `agent` no `opencode.json` é opcional quando os .md existem no diretório
7. `steps` substitui `maxSteps` (que não usamos, mas devemos documentar)
8. O plugin `@opencode-ai/plugin` pode precisar de atualização para 1.18.1

## Dependências

- **Pré-requisitos**: OpenCode 1.18.1 instalado, understanding do novo schema
- **Ordem**: Análise → Migração markdown → Migração RBAC → Features extras → Docs → Testes

## Tasks

### Task 1: Análise de compatibilidade — schema 1.18.1

- **Arquivo**: N/A (análise)
- **Descrição**: Verificar qual o schema exato do 1.18.1 para agentes e permissões.
  Confirmar se `permission.task` é o substituto nativo do `rbac` custom.
- **Dependências**: Nenhuma (primeira task)
- **Acceptance**:
  - Documentado: campos aceitos no frontmatter markdown (type, description, hidden, color, steps, temperature, top_p)
  - Documentado: formato de `permission.task` (como declarar quem pode chamar quem)
  - Documentado: se `agent.*.mode` no JSON é renomeado para `agent.*.type` ou se continua `mode`
  - Documentado: se agentes markdown são auto-descobertos ou precisam de referência
  - Documentado: se `rbac` custom ainda funciona ou é ignorado
- **Verify**:
  - Run: Verificar docs oficiais do OpenCode 1.18.1
  - Expected: Lista de campos válidos e formato de `permission.task`
- **Files**: N/A
- **Complexidade**: baixa

### Task 2: Criar agentes markdown puros com frontmatter 1.18.1

- **Arquivo**: `.config/opencode/agents/*.md` (5 arquivos)
- **Descrição**: Atualizar o frontmatter YAML de cada agente .md para incluir
  campos novos do 1.18.1. Cada agente manterá seu workflow completo (body markdown),
  mas o frontmatter será enriquecido.
- **Dependências**: Task 1 (schema confirmado)
- **Acceptance**:
  - Cada agente .md tem frontmatter com: `description` (required), `type` (ou `mode`),
    `hidden` (true para subagentes), `color` (cor distinta por agente)
  - `task-build`: `hidden: false`, `type: primary`, `color: blue`
  - `task-planner`: `hidden: true`, `type: subagent`, `color: green`
  - `dev`: `hidden: true`, `type: subagent`, `color: orange`
  - `code-review`: `hidden: true`, `type: subagent`, `color: purple`
  - `git-commit`: `hidden: true`, `type: subagent`, `color: gray`
  - Body markdown (workflows) permanece IDÊNTICO ao atual
  - Arquivos são válidos YAML frontmatter + Markdown body
- **Verify**:
  - Run: `head -10 .config/opencode/agents/task-build.md`
  - Expected: Frontmatter com description, type, hidden, color
  - Run: `grep -c "## Workflow" .config/opencode/agents/*.md`
  - Expected: 5 (todos mantêm workflow)
- **Files**: `.config/opencode/agents/task-build.md`, `.config/opencode/agents/task-planner.md`,
  `.config/opencode/agents/dev.md`, `.config/opencode/agents/code-review.md`,
  `.config/opencode/agents/git-commit.md`
- **Complexidade**: média

### Task 3: Migrar RBAC → permission.task no opencode.json

- **Arquivo**: `opencode.json`
- **Descrição**: Substituir o bloco `rbac` custom de cada agente pelo campo nativo
  `permission.task`. A seção `agent` no JSON será mantida para permissões de ferramentas
  (bash, read, edit, write, etc.), mas `rbac` será removida e substituída por `task`.
- **Dependências**: Task 1 (formato de `permission.task` confirmado)
- **Acceptance**:
  - Cada subagente tem `permission.task` em vez de `permission.rbac`
  - Formato: `"task": ["task-build"]` para subagentes (nega implícita dos outros)
  - OU: `"task": []` para subagentes que não podem chamar ninguém
  - `task-build` (primary) NÃO tem `permission.task` (pode chamar todos)
  - RBAC removida de todos os agentes
  - Permissões de ferramentas (bash, read, edit, write, question, skill) PRESERVADAS
  - Se `permission.task` não existir no 1.18.1, manter `rbac` como fallback documentado
- **Verify**:
  - Run: `python3 -c "import json; d=json.load(open('opencode.json')); print('rbac' not in str(d))"`
  - Expected: True (rbac removida)
  - Run: `python3 -c "import json; d=json.load(open('opencode.json')); [print(a, d['agent'][a].get('permission',{}).get('task','MISSING')) for a in d['agent']]"`
  - Expected: task-build=N/A, outros=definido
- **Files**: `opencode.json`
- **Complexidade**: média

### Task 4: Remover referências {file:...} do JSON (se auto-descobertos)

- **Arquivo**: `opencode.json`
- **Descrição**: Se o 1.18.1 auto-descobre agentes .md no diretório, remover
  a seção `agent` inteira do `opencode.json` (ou reduzir ao mínimo: apenas
  permissões de ferramentas). Se NÃO auto-descobere, manter `prompt: "{file:...}"`.
- **Dependências**: Task 1 (confirmar auto-descoberta), Task 3 (permission.task ok)
- **Acceptance**:
  - **Cenário A (auto-descobre)**: Seção `agent` removida do JSON; agentes são
    carregados apenas dos .md. Permissões de ferramentas movidas para frontmatter.
  - **Cenário B (não auto-descobre)**: Seção `agent` mantida com `prompt: "{file:...}"`,
    mas `rbac` substituída por `task` (já feito na Task 3)
  - Em ambos os cenários: `description` está no frontmatter (required pelo 1.18.1)
  - Documentado: qual cenário foi escolhido e por quê
- **Verify**:
  - Run: `python3 -c "import json; d=json.load(open('opencode.json')); print('agent' in d)"`
  - Expected: Depende do cenário (documentado)
- **Files**: `opencode.json`
- **Complexidade**: alta

### Task 5: Adicionar `steps` e features de criatividade

- **Arquivo**: `.config/opencode/agents/*.md` e/ou `opencode.json`
- **Descrição**: Adicionar `steps` onde `maxSteps` seria usado (se aplicável).
  Avaliar se `temperature`/`top_p` fazem sentido para algum agente (provavelmente
  não para git-commit ou code-review, talvez para brainstorming).
- **Dependências**: Task 2 (frontmatter atualizado)
- **Acceptance**:
  - Se algum agente usava `maxSteps`, migrado para `steps`
  - `temperature` e `top_p` documentados como opcionais (não adicionados se não fizer sentido)
  - Se adicionados: valores conservadores (temperature=0.3 para code-review, 0.7 para brainstorming)
  - Documentado: por que não adicionamos para agentes específicos
- **Verify**:
  - Run: `grep -r "steps\|maxSteps\|temperature" .config/opencode/agents/`
  - Expected: Documentado no plano qual cenário se aplica
- **Files**: `.config/opencode/agents/*.md`, potencialmente `opencode.json`
- **Complexidade**: baixa

### Task 6: Atualizar dependências npm

- **Arquivo**: `.config/opencode/package.json`
- **Descrição**: Atualizar `@opencode-ai/plugin` para versão compatível com 1.18.1.
  Verificar se há dependências novas necessárias.
- **Dependências**: Nenhuma (pode ser feita em paralelo com Tasks 2-5)
- **Acceptance**:
  - `@opencode-ai/plugin` atualizado para versão >= 1.18.1 (ou última disponível)
  - `npm install` roda sem erros
  - `package-lock.json` atualizado
  - Nenhuma dependência quebrada
- **Verify**:
  - Run: `cd .config/opencode && npm ls 2>&1 | head -5`
  - Expected: Sem erros de resolução
- **Files**: `.config/opencode/package.json`, `.config/opencode/package-lock.json`
- **Complexidade**: baixa

### Task 7: Atualizar AGENTS.md

- **Arquivo**: `AGENTS.md`
- **Descrição**: Atualizar documentação de convenções para refletir mudanças do 1.18.1.
  Atualizar seção "RBAC syntax" para documentar `permission.task`, atualizar
  referências a campos que mudaram.
- **Dependências**: Tasks 3, 4 (mudanças no JSON confirmadas)
- **Acceptance**:
  - Seção "RBAC syntax" renomeada para "permission.task syntax"
  - Documentado: formato de `permission.task` (novo padrão)
  - Referências a `rbac` atualizadas para `permission.task`
  - Seção "Agent Workflow" atualizada com novos campos (`hidden`, `color`)
  - Nenhuma referência quebrada a `rbac`
  - Seção "Skills e Subagentes" mantida (skills não mudaram)
- **Verify**:
  - Run: `grep -c "rbac" AGENTS.md`
  - Expected: 0 (ou apenas em contexto histórico)
  - Run: `grep -c "permission.task" AGENTS.md`
  - Expected: >= 2
- **Files**: `AGENTS.md`
- **Complexidade**: média

### Task 8: Atualizar MULTI_AGENT_ORCHESTRATION.md

- **Arquivo**: `docs/MULTI_AGENT_ORCHESTRATION.md`
- **Descrição**: Atualizar a documentação completa de orquestração para refletir
  o formato 1.18.1. Atualizar templates, exemplos, gotchas e anti-padrões.
- **Dependências**: Tasks 3, 4, 7 (todas as mudanças confirmadas)
- **Acceptance**:
  - Seção 4.3 "opencode.json — Campos Essenciais" atualizada com novos campos
  - Template opencode.json (8.1) atualizado
  - Template de Agente (8.2) atualizado com `type`, `hidden`, `color`
  - Seção 5 "RBAC e Permissões" renomeada para "Permissões e permission.task"
  - Gotchas (5.4) atualizadas com syntax de `permission.task`
  - Exemplos JSON atualizados (sem `rbac`, com `task`)
  - Tabela de permissões (5.2) mantida mas referenciando `permission.task`
  - Versão do sistema atualizada: "5 agentes + 50 skills → OpenCode 1.18.1"
  - Seção 11.4 "Agentes Built-in" expandida com General, Explore, Scout
- **Verify**:
  - Run: `grep -c "rbac" docs/MULTI_AGENT_ORCHESTRATION.md`
  - Expected: 0 (ou apenas em contexto histórico)
  - Run: `grep -c "permission.task" docs/MULTI_AGENT_ORCHESTRATION.md`
  - Expected: >= 5
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md`
- **Complexidade**: alta

### Task 9: Avaliar e documentar built-in agents (General, Explore, Scout)

- **Arquivo**: `docs/MULTI_AGENT_ORCHESTRATION.md` (seção 11.4)
- **Descrição**: Documentar os built-in agents do 1.18.1 (General, Explore, Scout)
  e avaliar se devem ser usados em conjunto com nossos agentes customizados.
  NÃO implementar — apenas documentar a análise e recomendação.
- **Dependências**: Task 1 (lista de built-ins confirmada)
- **Acceptance**:
  - Documentado: o que cada built-in faz (General=full subagent, Explore=read-only fast, Scout=dependency research)
  - Documentado: relação com nossos 5 agentes (sobreposição? complementaridade?)
  - Recomendação: usar Explore em vez de ferramentas manuais de busca? Usar Scout para research?
  - Decisão: manter nossos 5 agentes como está (built-ins são complementares, não substitutos)
  - Tabela comparativa: nossos agentes vs. built-ins
- **Verify**:
  - Run: `grep -c "General\|Explore\|Scout" docs/MULTI_AGENT_ORCHESTRATION.md`
  - Expected: >= 6
- **Files**: `docs/MULTI_AGENT_ORCHESTRATION.md`
- **Complexidade**: baixa

### Task 10: Atualizar SESSION_CONTEXT e limpar referências obsoletas

- **Arquivo**: `docs/SESSION_CONTEXT_20260618.md`
- **Descrição**: Criar entrada de sessão documentando a migração para 1.18.1.
  Atualizar referências a versão do sistema. Verificar se há referências
  a `maxSteps` ou outros campos deprecated em qualquer arquivo.
- **Dependências**: Tasks 7, 8 (docs atualizadas)
- **Acceptance**:
  - Nova entrada no SESSION_CONTEXT documentando: data, versão 1.18.1, mudanças feitas
  - Nenhuma referência a `maxSteps` em nenhum arquivo do projeto
  - Nenhuma referência a `rbac` que não seja contextual/histórica
  - `package.json` reflete versão atualizada do plugin
- **Verify**:
  - Run: `grep -r "maxSteps" . --include="*.md" --include="*.json" 2>/dev/null`
  - Expected: Nenhum resultado
  - Run: `grep -r "mode.*primary\|mode.*subagent" .config/opencode/agents/`
  - Expected: Substituído por `type` (se aplicável)
- **Files**: `docs/SESSION_CONTEXT_20260618.md`, verificação global
- **Complexidade**: baixa

### Task 11: Verificação final e smoke test

- **Arquivo**: N/A (verificação)
- **Descrição**: Rodar verificações finais para garantir que tudo está coerente.
  Syntax check em JSON, validação de frontmatter, verificação de que nenhum
  campo foi perdido na migração.
- **Dependências**: Tasks 1-10 (todas concluídas)
- **Acceptance**:
  - `opencode.json` é JSON válido (parse sem erros)
  - Todos os 5 .md agents têm frontmatter YAML válido
  - Todos os workflows preservados (grep por seções-chave)
  - `permission.task` presente onde deveria estar
  - `rbac` ausente (ou apenas em docs como referência histórica)
  - `hidden: true` em todos os subagentes
  - `color` definido em todos os agentes
  - `description` presente em todos os agentes
  - Nenhuma referência quebrada a arquivos
  - AGENTS.md coerente com nova config
  - MULTI_AGENT_ORCHESTRATION.md coerente com nova config
- **Verify**:
  - Run: `python3 -c "import json; json.load(open('opencode.json')); print('JSON válido')"`
  - Expected: "JSON válido"
  - Run: `for f in .config/opencode/agents/*.md; do head -1 "$f"; done`
  - Expected: "---" em todos (frontmatter válido)
  - Run: `grep -c "## Workflow" .config/opencode/agents/*.md`
  - Expected: 5 (todos mantêm workflow)
  - Run: `grep -c "permission.task\|\"task\"" AGENTS.md docs/MULTI_AGENT_ORCHESTRATION.md`
  - Expected: >= 10
- **Files**: Todos os arquivos modificados
- **Complexidade**: média

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| `permission.task` tem formato diferente do esperado | Média | Alto | Task 1 investiga antes; se incompatível, manter `rbac` como fallback documentado |
| Auto-descoberta de agentes .md não funciona como esperado | Média | Alto | Task 4 tem dois cenários (A/B); se auto-descoberta falhar, manter `{file:...}` |
| `mode` no frontmatter é renomeado para `type` no 1.18.1 | Baixa | Médio | Task 2 testa ambos; documentar qual funciona |
| `@opencode-ai/plugin` 1.18.1 tem breaking changes | Baixa | Alto | Task 6 atualiza e testa; rollback se necessário |
| Agentes .md perdem funcionalidade sem o JSON agent block | Baixa | Alto | Manter JSON como backup durante transição; testar cada agente individualmente |
| `hidden` esconde agentes que deveriam aparecer | Baixa | Baixo | Apenas `task-build` fica visível (comportamento atual); testar no TUI |
| `color` não é suportado no terminal do usuário | Baixa | Baixo | Feature cosmética; sem impacto funcional |
| Skills system mudou no 1.18.1 | Baixa | Alto | Task 1 verifica; se mudou, adicionar task extra de migração de skills |

## Ordem de Implementação

```
Fase 1: Análise (paralelo)
├── Task 1: Análise de compatibilidade
└── Task 6: Atualizar dependências npm

Fase 2: Migração core (sequencial, depende da Task 1)
├── Task 2: Atualizar frontmatter dos agentes .md
├── Task 3: Migrar RBAC → permission.task
├── Task 4: Remover/manter referências {file:...}
└── Task 5: Adicionar steps e features extras

Fase 3: Documentação (paralelo, depende da Fase 2)
├── Task 7: Atualizar AGENTS.md
├── Task 8: Atualizar MULTI_AGENT_ORCHESTRATION.md
├── Task 9: Avaliar built-in agents
└── Task 10: Atualizar SESSION_CONTEXT

Fase 4: Verificação (depende da Fase 3)
└── Task 11: Verificação final e smoke test
```

> **Nota**: Tasks 2-4 podem ser feitas em paralelo se os resultados da Task 1
> estiverem claros. Tasks 7-10 podem ser feitas em paralelo após Fase 2.

## Verificação Final

```bash
# 1. JSON válido
python3 -c "import json; json.load(open('opencode.json')); print('JSON válido')"

# 2. Frontmatter válido em todos os agents
for f in .config/opencode/agents/*.md; do
  head -1 "$f" | grep -q "^---" && echo "OK: $f" || echo "FAIL: $f"
done

# 3. Workflows preservados
grep -c "## Workflow" .config/opencode/agents/*.md

# 4. RBAC removida do JSON
python3 -c "
import json
d = json.load(open('opencode.json'))
has_rbac = 'rbac' in json.dumps(d)
print('RBAC removida' if not has_rbac else 'ERRO: rbac ainda presente')
"

# 5. permission.task presente
python3 -c "
import json
d = json.load(open('opencode.json'))
for name, agent in d.get('agent', {}).items():
    perm = agent.get('permission', {})
    task = perm.get('task', 'MISSING')
    print(f'{name}: task={task}')
"

# 6. hidden e color nos .md
grep -l "hidden:" .config/opencode/agents/*.md | wc -l
# Expected: 5

grep -l "color:" .config/opencode/agents/*.md | wc -l
# Expected: 5

# 7. Referências atualizadas
grep -c "permission.task" AGENTS.md docs/MULTI_AGENT_ORCHESTRATION.md
# Expected: >= 10

# 8. Nenhuma referência obsoleta
grep -r "maxSteps" . --include="*.md" --include="*.json" 2>/dev/null | wc -l
# Expected: 0

# 9. Documentação coerente
grep -q "1.18" docs/MULTI_AGENT_ORCHESTRATION.md && echo "Versão atualizada" || echo "ERRO"

# 10. Scripts intactos (não foram modificados)
bash -n run-cloudflare-tunnel.sh && echo "Cloudflare OK"
bash -n run-opencode-tailscale.sh && echo "Tailscale OK"
bash -n bin/opencode-web.sh && echo "opencode-web OK"
bash -n bin/opencode-tailscale.sh && echo "opencode-tailscale OK"
```
