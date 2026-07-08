# Plano: Unificação de Skills de Design/Frontend

**Data:** 2026-07-07
**Tipo:** Tarefa média (4 skills → 2, ~15 arquivos afetados)
**Status:** Aguardando aprovação

## Objetivo

Unificar 4 skills com sobreposição em 2 skills consolidadas, seguindo a estratégia aprovada "Unificada + referência upstream":
- `design-system-patterns` + `design-tokens` → `design-system`
- `frontend-design` + `designing-frontend-interfaces` → `frontend-complete`

## Escopo

**Dentro:**
- Criar 2 novas skills unificadas (`design-system`, `frontend-complete`)
- Mesclar todo o conteúdo relevante das 4 skills originais
- Manter referências ao upstream `synapse-ai-hub/opencode-skills`
- Remover as 4 skills originais (diretórios + entradas opencode.json)
- Atualizar AGENTS.md (seção skills)
- Atualizar README.md (menções a skills e numeração)
- Atualizar docs/ (MULTI_AGENT_ORCHESTRATION.md, SESSION_CONTEXT_20260618.md, AGENTS_TEMPLATE.md, ADR-008)
- Verificar agents/ para referências a skills antigas
- Atualizar skills que mencionam `frontend-design` (brainstorming, using-superpowers)
- Atualizar numeração de skills (51 → 49) em todos os arquivos
- Remover referências a "parecer_descritivo" nas skills e documentação

**Fora:**
- Alterar quaisquer outras skills
- Modificar agentes ou configurações de RBAC
- Alterar o fluxo de trabalho existente

## Análise de Conteúdo

### Par 1: design-system-patterns + design-tokens

| Skill | Arquivos | Conteúdo principal |
|---|---|---|
| `design-system-patterns` | SKILL.md (115L) + references/ (4 arquivos: details.md 219L, design-tokens.md 420L, component-architecture.md 617L, theming-architecture.md 521L) | Design system completo: tokens + theming + componentes + pipeline Figma |
| `design-tokens` | SKILL.md (208L) + REFERENCE.md (364L) | Tokens CSS, theme switching, JSON format, Tailwind integration, migration guides |

**Conteúdo único de cada:**
- `design-system-patterns`: component architecture (compound, polymorphic, CVA, slots, headless), Style Dictionary pipeline, Figma sync
- `design-tokens`: JSON token format, responsive tokens, Tailwind CSS integration, token governance/deprecation, migration guides (hardcoded → CSS vars, Sass → CSS vars)

**Estratégia:** Manter `design-system` como skill unificada. Mover references/ para a nova skill.

### Par 2: frontend-design + designing-frontend-interfaces

| Skill | Arquivos | Conteúdo principal |
|---|---|---|
| `frontend-design` | SKILL.md (55L) | Filosofia de design: escolhas deliberadas, tipografia com personalidade, motion intencional, processo brainstorm→explore→plan→build, escrita em design |
| `designing-frontend-interfaces` | SKILL.md (43L) | Implementação de UIs: design thinking, aesthetics guidelines, evitar AI slop, CSS variables, motion |

**Conteúdo único de cada:**
- `frontend-design`: processo detalhado (2 passes), self-critique, design de copy, escrita em UI (nomeação, voz ativa, falha/vazio)
- `designing-frontend-interfaces`: guidelines técnicas de estética, specifics sobre CSS variables, motion CSS-only vs Motion library

**Estratégia:** Manter `frontend-complete` como skill unificada. `frontend-design` tem conteúdo mais denso e único; `designing-frontend-interfaces` complementa com aspects técnicos.

### Referências cruzadas encontradas

**Skills que mencionam `frontend-design`:**
- `.config/opencode/skills/brainstorming/SKILL.md` (linha 61): "Do NOT invoke frontend-design"
- `.config/opencode/skills/using-superpowers/SKILL.md` (linha 106): "Implementation skills second (frontend-design, mcp-builder)"

**Agents:** Nenhuma referência direta a skills antigas encontrada em `.config/opencode/agents/`.

**Documentação com referências:**
- `README.md`: 41 skills, design-system-patterns, design-tokens, parecer_descritivo
- `docs/MULTI_AGENT_ORCHESTRATION.md`: 41 skills, parecer_descritivo, design-system-patterns, design-tokens
- `docs/SESSION_CONTEXT_20260618.md`: Muitas referências históricas (documento histórico)
- `docs/AGENTS_TEMPLATE.md`: 41 skills, parecer_descritivo como exemplo
- `docs/decisions/ADR-008-adicao-skills-upstream.md`: 41 skills

## Assumptions

1. O upstream `synapse-ai-hub/opencode-skills` não mudou desde a instalação (verificar antes de implementar)
2. A configuração do opencode.json para paths de skills não precisa mudar (diretórios novos)
3. Outras skills que referenciam `design-system-patterns` ou `design-tokens` não existem (nenhuma referência cruzada encontrada)
4. O `user-invocable: false` do design-tokens deve ser preservado na skill unificada
5. `docs/SESSION_CONTEXT_20260618.md` é documento histórico — manter referências originais mas adicionar nota
6. `.env` referencia `PROJECT_DIR=/root/Projetos/parecer_descritivo` — é config funcional, não skill

## Tasks

### Task 1: Criar skill `design-system`

**Acceptance:**
- Diretório `.config/opencode/skills/design-system/` criado
- `SKILL.md` com frontmatter correto (name, description abrangente)
- Seção "Referências" listando skills upstream originais
- `references/` com 4 arquivos movidos de design-system-patterns + REFERENCE.md de design-tokens

**Verify:**
- `ls .config/opencode/skills/design-system/` mostra SKILL.md + references/
- Conteúdo do SKILL.md combina tokens, theming, componentes, pipeline

**Files:**
- Criar: `.config/opencode/skills/design-system/SKILL.md`
- Mover: `.config/opencode/skills/design-system-patterns/references/*` → `.config/opencode/skills/design-system/references/`
- Mover: `.config/opencode/skills/design-tokens/REFERENCE.md` → `.config/opencode/skills/design-system/references/tokens-reference.md`

**Complexidade:** Média

---

### Task 2: Criar skill `frontend-complete`

**Acceptance:**
- Diretório `.config/opencode/skills/frontend-complete/` criado
- `SKILL.md` com frontmatter correto (name, description abrangente)
- Seção "Referências" listando skills upstream originais
- Conteúdo mesclado de frontend-design (filosofia, processo, escrita) + designing-frontend-interfaces (aesthetics, implementação)

**Verify:**
- `ls .config/opencode/skills/frontend-complete/` mostra SKILL.md
- Conteúdo do SKILL.md cobre: design thinking, aesthetics guidelines, processo, escrita, motion

**Files:**
- Criar: `.config/opencode/skills/frontend-complete/SKILL.md`

**Complexidade:** Média

---

### Task 3: Remover skills antigas

**Acceptance:**
- 4 diretórios removidos: `design-system-patterns/`, `design-tokens/`, `frontend-design/`, `designing-frontend-interfaces/`
- Nenhum arquivo restante em nenhum dos 4 diretórios

**Verify:**
- `ls .config/opencode/skills/ | grep -E "design-system-patterns|design-tokens|frontend-design|designing-frontend"` retorna vazio

**Files:**
- Remover: `.config/opencode/skills/design-system-patterns/` (todo o diretório)
- Remover: `.config/opencode/skills/design-tokens/` (todo o diretório)
- Remover: `.config/opencode/skills/frontend-design/` (todo o diretório)
- Remover: `.config/opencode/skills/designing-frontend-interfaces/` (todo o diretório)

**Complexidade:** Baixa

---

### Task 4: Atualizar opencode.json

**Acceptance:**
- Remover 4 entradas antigas de `permission.skill`: `design-system-patterns`, `design-tokens`, `frontend-design`, `designing-frontend-interfaces`
- Adicionar 2 entradas novas: `design-system`, `frontend-complete`
- Total de skills no permission.skill: 49 (51 - 4 + 2 = 49)

**Verify:**
- `grep -c '"allow"' opencode.json` retorna 49
- `grep "design-system" opencode.json` mostra apenas a entrada nova
- `grep "frontend-complete" opencode.json` mostra a entrada nova
- JSON válido: `python3 -c "import json; json.load(open('opencode.json'))"`

**Files:**
- Editar: `opencode.json` (seção permission.skill)

**Complexidade:** Baixa

---

### Task 5: Atualizar AGENTS.md + Verificar agents e documentação

**Acceptance:**
- Seção "Skills e Subagentes" reflete as 49 skills (não 51)
- Referências a `design-system-patterns` e `design-tokens` atualizadas para `design-system`
- Referências a `frontend-design` e `designing-frontend-interfaces` atualizadas para `frontend-complete`
- Estrutura de diretórios atualizada
- Referências a "movido de parecer_descritivo" atualizadas ou removidas
- Agents verificados (nenhum menciona skills antigas — OK)
- Todas as menções a "51 skills" atualizadas para "49 skills"

**Verify:**
- `grep "design-system-patterns" AGENTS.md` retorna vazio
- `grep "design-system" AGENTS.md` mostra referências atualizadas
- `grep "51 skills" AGENTS.md` retorna vazio (atualizado para 49)
- `grep "parecer_descritivo" AGENTS.md` retorna vazio ou apenas referências contextuais

**Files:**
- Editar: `AGENTS.md` (seções: Skills e Subagentes, Estrutura, Convenções)

**Complexidade:** Baixa

---

### Task 6: Atualizar skills que mencionam `frontend-design`

**Acceptance:**
- `.config/opencode/skills/brainstorming/SKILL.md`: referência a `frontend-design` atualizada para `frontend-complete`
- `.config/opencode/skills/using-superpowers/SKILL.md`: referência a `frontend-design` atualizada para `frontend-complete`
- Skills não quebradas após atualização

**Verify:**
- `grep "frontend-design" .config/opencode/skills/brainstorming/SKILL.md` retorna vazio
- `grep "frontend-design" .config/opencode/skills/using-superpowers/SKILL.md` retorna vazio
- `grep "frontend-complete" .config/opencode/skills/brainstorming/SKILL.md` mostra referência atualizada
- `grep "frontend-complete" .config/opencode/skills/using-superpowers/SKILL.md` mostra referência atualizada

**Files:**
- Editar: `.config/opencode/skills/brainstorming/SKILL.md` (linha 61)
- Editar: `.config/opencode/skills/using-superpowers/SKILL.md` (linha 106)

**Complexidade:** Baixa

---

### Task 7: Atualizar numeração e referências em documentação

**Acceptance:**
- `README.md`: numeração atualizada de 41 para 49 skills, referências a skills antigas removidas
- `docs/MULTI_AGENT_ORCHESTRATION.md`: numeração atualizada, referências a parecer_descritivo e skills antigas removidas
- `docs/AGENTS_TEMPLATE.md`: numeração atualizada, referência a parecer_descritivo atualizada
- `docs/decisions/ADR-008-adicao-skills-upstream.md`: numeração atualizada
- `docs/SESSION_CONTEXT_20260618.md`: NOTA adicionada indicando documento histórico com dados da época
- Todos os arquivos mencionam 49 skills (não 41 nem 51)

**Verify:**
- `grep -n "41 skills" README.md docs/MULTI_AGENT_ORCHESTRATION.md docs/AGENTS_TEMPLATE.md` retorna vazio
- `grep -n "51 skills" README.md docs/MULTI_AGENT_ORCHESTRATION.md docs/AGENTS_TEMPLATE.md` retorna vazio
- `grep -n "49 skills" README.md docs/MULTI_AGENT_ORCHESTRATION.md docs/AGENTS_TEMPLATE.md` mostra atualizações
- `grep "design-system-patterns\|design-tokens" README.md` retorna vazio
- `grep "parecer_descritivo" README.md` retorna vazio ou apenas referências contextuais

**Files:**
- Editar: `README.md` (linhas 25, 28-29, 355, 404)
- Editar: `docs/MULTI_AGENT_ORCHESTRATION.md` (linhas 4, 165, 174-175, 232, 537)
- Editar: `docs/AGENTS_TEMPLATE.md` (linhas 11, 37)
- Editar: `docs/decisions/ADR-008-adicao-skills-upstream.md` (linha 33)
- Editar: `docs/SESSION_CONTEXT_20260618.md` (adicionar nota de contexto histórico)

**Complexidade:** Média

---

### Task 8: Verificação final

**Acceptance:**
- Skills novas funcionam (frontmatter válido, sem erros de sintaxe)
- Nenhuma referência quebrada a skills antigas em nenhum arquivo
- opencode.json válido
- Documentação consistente
- Numeração correta (49) em todos os arquivos

**Verify:**
- `python3 -c "import yaml; yaml.safe_load(open('.config/opencode/skills/design-system/SKILL.md').read().split('---')[1])"` (frontmatter válido)
- `python3 -c "import yaml; yaml.safe_load(open('.config/opencode/skills/frontend-complete/SKILL.md').read().split('---')[1])"` (frontmatter válido)
- `grep -r "design-system-patterns\|design-tokens\|frontend-design\|designing-frontend-interfaces" .config/opencode/ opencode.json AGENTS.md README.md docs/` retorna vazio (exceto SESSION_CONTEXT)
- `grep -rn "41 skills\|51 skills" . README.md docs/` retorna vazio

**Files:** Nenhum (verificação only)

**Complexidade:** Baixa

## Riscos

| Risco | Mitigação |
|---|---|
| Perder conteúdo relevante ao mesclar | Análise detalhada feita; todo conteúdo único identificado e preservado |
| Referências quebradas em outras skills | Task 6 verifica e atualiza skills que mencionam frontend-design |
| Frontmatter inválido nas skills novas | Task 8 valida frontmatter via YAML parse |
| opencode.json com JSON inválido | Task 4 valida via python3 json.load() |
| Perda de funcionalidade para usuários | Descrições das skills novas são mais abrangentes; cobrem tudo das originais |
| Documentação desatualizada | Task 7 atualiza todos os arquivos de documentação |
| Referências históricas incorretas | SESSION_CONTEXT mantido como histórico com nota explicativa |

## Ordem de Implementação

```
Task 1 (design-system)     ─┐
                             ├→ Task 4 (opencode.json) → Task 5 (AGENTS.md) → Task 8 (verificação)
Task 2 (frontend-complete) ─┘         ↓                      ↓
                              Task 6 (skills refs)    Task 7 (docs/numeração)
                                       ↓                      ↓
                              Task 3 (remover antigas) ───────┘
```

**Nota:** Tasks 1 e 2 são independentes e podem rodar em paralelo. Tasks 6 e 7 são independentes e podem rodar em paralelo após Task 4.

## Verificação Final

1. Todas as 8 tasks concluídas
2. `opencode.json` válido e com 49 skills
3. Nenhuma referência às skills antigas em nenhum arquivo (exceto SESSION_CONTEXT como histórico)
4. Skills novas com frontmatter YAML válido
5. AGENTS.md consistente com a realidade
6. README.md atualizado com 49 skills
7. Todos os docs/ atualizados com numeração correta
8. Skills brainstorming e using-superpowers com referências atualizadas

## Referências Upstream

As skills unificadas devem incluir esta seção:

```markdown
## Referências

**Origem:** Skills originais do repositório `synapse-ai-hub/opencode-skills`:
- `design-system-patterns` — patterns de design system (tokens, theming, componentes)
- `design-tokens` — arquitetura de tokens CSS e theme systems

**Nota:** Esta skill é uma unificação local. Quando o upstream atualizar,
verificar se há mudanças relevantes nestas skills originais.
```
