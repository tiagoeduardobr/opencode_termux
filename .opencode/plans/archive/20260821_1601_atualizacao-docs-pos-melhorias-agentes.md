# Plano: Atualização de documentação pós-melhorias dos agentes (RETRY)

## Objetivo

Sincronizar a documentação do repositório (`AGENTS.md`, `docs/MULTI_AGENT_ORCHESTRATION.md`, `docs/SESSION_CONTEXT_20260618.md`, `README.md`) com as 5 rodadas de melhorias nos agentes (commits `58fc4ea`, `609d579`, `68e2b11`, `825294a`, `5a1bf2b` — ~918 linhas adicionadas aos prompts dos 5 agentes entre 19–21/08/2026).

**Fonte de verdade das melhorias**: mensagens completas dos 5 commits (obtidas via `git log -1 --format=%B <hash>`).

## Escopo

- **Dentro**: atualização das 4 docs listadas; seções específicas identificadas na exploração (ver tasks); nova seção cronológica no SESSION_CONTEXT.
- **Fora**: modificação dos prompts dos agentes (`.config/opencode/agents/*.md`); criação de ADRs novos; alteração em `opencode.json`; reescrita de seções já atualizadas (6.1–6.3 do orchestration guide, feitas no commit `58fc4ea`).

## Assumptions

1. As mensagens dos 5 commits são o resumo canônico das melhorias (não é necessário reler os diffs completos linha a linha).
2. `docs/MULTI_AGENT_ORCHESTRATION.md` permanece a fonte de verdade detalhada; AGENTS.md e README.md mantêm o padrão atual "resumo curto + link para o guia completo".
3. SESSION_CONTEXT segue seu padrão cronológico existente (seções "Mudanças..." com data).
4. Não há plano anterior desta tarefa em `.opencode/plans/` (RETRY anterior não salvou arquivo) — este plano é criado do zero.
5. Idioma da documentação: PT-BR (padrão do repo), exceto termos técnicos.

## Dependências

### Matriz de Dependências

| Task | Depende de | Premissa |
|------|-----------|----------|
| Task 2 (AGENTS.md) | Task 1 | Terminologia e resumos definidos primeiro no guia completo |
| Task 3 (SESSION_CONTEXT) | Task 1 | Mesma terminologia canônica |
| Task 4 (README.md) | Task 1 | Mesma terminologia canônica |

**Regra**: Tasks 2, 3, 4 são independentes entre si → podem executar em paralelo após Task 1.

### Pré-requisitos

- Branch feature criada a partir de `main` (delegado ao `git-commit`)
- Commits `58fc4ea..5a1bf2b` presentes no histórico (confirmado)

### Ordem de Implementação

1. Task 1 → 2. Tasks 2, 3, 4 (paralelizáveis)

## Tasks

- [x] **Task 1: Atualizar `docs/MULTI_AGENT_ORCHESTRATION.md`**
  - Acceptance: Given o guia de orquestração como fonte de verdade, When as seções 2, 10 e 11.2 forem atualizadas, Then cada um dos 5 agentes terá suas novas capacidades descritas e a seção 10 cobrirá as 5 rodadas com os hashes de commit.
  - Verify: `grep -c "HALF_OPEN\|output contract\|Given/When/Then\|OWASP\|50/72" docs/MULTI_AGENT_ORCHESTRATION.md` retorna ≥ 5 matches; `grep "5a1bf2b" docs/MULTI_AGENT_ORCHESTRATION.md` encontra o hash.
  - Files: `docs/MULTI_AGENT_ORCHESTRATION.md`
  - Complexidade: média
  - Mudanças por seção:
    - **Seção 2.1 task-build**: adicionar às Responsabilidades — retry policy com backoff exponencial + jitter; circuit breaker HALF_OPEN (já descrito na seção 6.1, apenas referenciar); output contracts padronizados para os 5 subagentes; context budgeting (máx. 200 linhas por prompt de subagente); routing table (7 mapeamentos tipo-de-task → agente → pipeline); checkpoints expandidos (`resumivel`, `proximo_passo`, `contexto_necessario`) [ref. seção 6.3]; branch-only delegation guard.
    - **Seção 2.2 task-planner**: adicionar — critérios de aceitação Given/When/Then (step 3a); escala numérica de complexidade (step 6a); heurísticas de decomposição (step 6.1); matriz de dependências; framework de risco em 3 dimensões; checkpoints para planos >6 tasks (step 6b); evaluator-optimizer loop máx. 2 iterações (step 6c); feature list JSON estruturada (step 6d); tabela de 8 anti-padrões de planejamento.
    - **Seção 2.3 dev**: adicionar — pre-analysis decomposition antes de implementar; stop conditions (blocos PARAR/NÃO PARAR/NÃO FAZER); output template com 6 seções; auto-verificação com 3 categorias de erro; 8 restrições de escopo; citação de arquivos com números de linha; few-shot pattern (buscar exemplos antes de implementar); escalation ladder quando bloqueado; timeout policy com 4 parâmetros; context budget (máx. 5 skills dinâmicas); tabela de anti-padrões.
    - **Seção 2.4 code-review**: adicionar — persona Senior Reviewer; structured findings com severidade formal (Critical/High/Medium/Low); context gathering além do diff (5 steps); security scan dedicado OWASP Top 10; source of truth discipline; formato no-findings (Findings/Residual Risks/Gaps); checks por framework (Python, Node.js, Shell, Docker); depth tiers (Basic/Standard/Comprehensive); output contract com 3 vereditos; tabela de 10 anti-padrões do reviewer.
    - **Seção 2.5 git-commit**: adicionar — tipos Conventional Commits completos (+style, perf, build, ci, revert); regra 50/72 e modo imperativo; staging strategy (`git add -p` + fallback não-interativo); atomic commits (sem `git add -A`); validação pré-commit (secrets, .env, build artifacts); formato completo de mensagem (body/footer via heredoc); breaking change detection (`!` + footer BREAKING CHANGE); scope auto-detection; convenção Co-Authored-By; multi-commit workflow; output contract para integração com task-build.
    - **Seção 10 (Melhorias Recentes)**: substituir parágrafo único por lista cronológica das 5 rodadas com hashes: `58fc4ea` (task-build, 19/08), `609d579` (dev, 19/08), `68e2b11` (task-planner, 20/08), `825294a` (code-review, 20/08), `5a1bf2b` (git-commit, 21/08). Preservar menção ao que já existia.
    - **Seção 11.2 (Skills Relevantes)**: verificar se a coluna "Usado por" reflete as skills agora obrigatórias nos prompts atualizados (ex.: `verification-before-completion` no dev; ajustar somente se divergente).

- [ ] **Task 2: Atualizar `AGENTS.md`**
  - Acceptance: Given que AGENTS.md é lido por todo agente no step 0, When a seção Melhorias Recentes for atualizada, Then ela conterá entradas para as 5 rodadas (19–21/08/2026) com hashes, mantendo o padrão de bullet conciso.
  - Verify: `grep -c "58fc4ea\|609d579\|68e2b11\|825294a\|5a1bf2b" AGENTS.md` retorna ≥ 5; `grep "melhorias.*agentes\|task-planner.*checkpoints\|git-commit.*Conventional" AGENTS.md` encontra referências.
  - Files: `AGENTS.md`
  - Complexidade: baixa
  - Mudanças por seção:
    - **Seção "Skills e Subagentes"**: nenhuma mudança estrutural necessária (lista de agentes não mudou); opcionalmente mencionar que os 5 prompts foram reforçados em 19–21/08/2026.
    - **Seção "Agent Workflow — Orquestração"**: no item "Loop de trabalho", adicionar menção de 1 linha aos novos mecanismos (output contracts, circuit breaker HALF_OPEN, routing table) com link para seções 2 e 6 do guia completo.
    - **Seção "Melhorias Recentes"**: acrescentar 5 bullets no final (antes da linha "Para uma lista completa..."), um por rodada, formato: `- Melhorias nos agentes (19–21/08/2026): task-build (<hash>) ...` ou 5 bullets separados seguindo o estilo existente. Conteúdo espelhar Task 1 de forma condensada.

- [ ] **Task 3: Atualizar `docs/SESSION_CONTEXT_20260618.md`**
  - Acceptance: Given o padrão cronológico do arquivo, When a nova seção de mudanças for adicionada, Then existirá seção "Melhorias nos Agentes (19–21/08/2026)" listando as 5 rodadas com commits, e a seção Subagentes mencionará o reforço.
  - Verify: `grep "19–21/08/2026\|21/08/2026" docs/SESSION_CONTEXT_20260618.md` encontra a nova seção; `grep -c "58fc4ea\|609d579\|68e2b11\|825294a\|5a1bf2b" docs/SESSION_CONTEXT_20260618.md` retorna ≥ 5.
  - Files: `docs/SESSION_CONTEXT_20260618.md`
  - Complexidade: baixa
  - Mudanças por seção:
    - **Seção "Subagentes (5)"**: adicionar nota abaixo da tabela: prompts reforçados em 19–21/08/2026 (detalhes em MULTI_AGENT_ORCHESTRATION.md §2 e §10).
    - **Nova seção no final** (após "Atualização OpenCode 1.18.18"): `### Melhorias nos Agentes (19–21/08/2026)` com sub-bullets por agente/commit seguindo o estilo das seções anteriores (título com data, bullets curtos).

- [x] **Task 4: Atualizar `README.md`**
  - Acceptance: Given que README é a porta de entrada do tutorial, When a seção Skills e Subagentes for atualizada, Then a nota de skills obrigatórias refletirá os prompts atuais e haverá link para o guia de orquestração.
  - Verify: `grep "MULTI_AGENT_ORCHESTRATION" README.md` encontra referência na seção de subagentes; tabela de agentes mantém 5 linhas válidas.
  - Files: `README.md`
  - Complexidade: baixa
  - Mudanças por seção:
    - **Seção "Skills e Subagentes"**: corrigir contagem de skills se divergente (linha 404 diz "27 globais + 14 superpowers + 8 upstream + plan-reviewer"; AGENTS.md diz "27 globais + 14 + 10 novas upstream" — reconciliar com `ls .config/opencode/skills/ | wc -l`); atualizar nota de skills obrigatórias conforme frontmatter/prompts atuais; adicionar 1 linha: "Prompts dos 5 agentes reforçados em 19–21/08/2026 — detalhes em `docs/MULTI_AGENT_ORCHESTRATION.md`".

## Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Inconsistência terminológica entre as 4 docs (mesmo conceito com nomes diferentes) | Média | Médio | Task 1 executa primeiro e define termos canônicos; Tasks 2–4 copiam terminologia dela |
| Duplicação/conflito com conteúdo já atualizado (seções 6.1–6.3 feitas no commit `58fc4ea`) | Média | Baixo | Escopo explícito por seção nas tasks; seções 6.x fora do escopo, apenas referenciadas |
| Contagem de skills divergente entre README e AGENTS.md | Alta | Baixo | Task 4 inclui verificação empírica `ls .config/opencode/skills/ \| wc -l` antes de editar |
| Docs ficarem verbosas demais (perda do padrão conciso) | Baixa | Baixo | Seguir padrão existente: resumo curto + link para guia completo; bullets de 1–2 linhas |

## Verificação Final

```bash
# 1. Todos os hashes presentes nas 4 docs
for f in AGENTS.md README.md docs/MULTI_AGENT_ORCHESTRATION.md docs/SESSION_CONTEXT_20260618.md; do
  echo "== $f =="; grep -c "58fc4ea\|609d579\|68e2b11\|825294a\|5a1bf2b" "$f"
done

# 2. Links internos não quebrados (referências a arquivos/seções citados)
grep -n "MULTI_AGENT_ORCHESTRATION.md" AGENTS.md README.md docs/SESSION_CONTEXT_20260618.md

# 3. Renderização markdown ok (sem tabelas quebradas)
grep -c "^|" docs/MULTI_AGENT_ORCHESTRATION.md README.md
```

Expected: cada doc com ≥ 1 ocorrência dos hashes (orchestration ≥ 5); links apontando para arquivos existentes; sem regressão visual nas tabelas.

## Feature List

```json
{
  "features": [
    {
      "id": 1,
      "name": "Atualizar docs/MULTI_AGENT_ORCHESTRATION.md (seções 2, 10, 11.2)",
      "status": "pending",
      "acceptance": [
        "Given o guia de orquestração como fonte de verdade",
        "When as seções 2, 10 e 11.2 forem atualizadas",
        "Then os 5 agentes terão capacidades novas descritas e a seção 10 cobrirá as 5 rodadas com hashes"
      ]
    },
    {
      "id": 2,
      "name": "Atualizar AGENTS.md (Melhorias Recentes + Loop de trabalho)",
      "status": "pending",
      "acceptance": [
        "Given que AGENTS.md é lido por todo agente no step 0",
        "When a seção Melhorias Recentes for atualizada",
        "Then conterá entradas das 5 rodadas (19–21/08/2026) com hashes"
      ]
    },
    {
      "id": 3,
      "name": "Atualizar docs/SESSION_CONTEXT_20260618.md (Subagentes + nova seção cronológica)",
      "status": "pending",
      "acceptance": [
        "Given o padrão cronológico do arquivo",
        "When a nova seção for adicionada",
        "Then existirá seção das melhorias 19–21/08/2026 com os 5 commits"
      ]
    },
    {
      "id": 4,
      "name": "Atualizar README.md (seção Skills e Subagentes)",
      "status": "pending",
      "acceptance": [
        "Given que README é a porta de entrada",
        "When a seção Skills e Subagentes for atualizada",
        "Then skills obrigatórias refletirão prompts atuais e haverá link para o guia de orquestração"
      ]
    }
  ]
}
