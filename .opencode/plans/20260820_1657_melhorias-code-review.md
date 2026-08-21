# Plano: Melhorias no code-review.md (10 tasks)

> **Revisão v2 (20/08/2026:18:28)**: Aplicadas 7 sugestões do code review do
> plano v1 — (1) URLs das 6 fontes primárias, (2) description do frontmatter
> em C1, (3) tier Comprehensive ajustado ao timeout do task-build em I5,
> (4) correção da instrução de skills de segurança em C4, (5) dependência
> C2↔I1/I2 documentada, (6) nota sobre deslocamento de linhas, (7) seção
> Teste Funcional. Estrutura e numeração das tasks preservadas.

## Objetivo

Implementar 10 melhorias fundamentais ao agente `code-review.md` para
transformá-lo de um revisor genérico em um **senior code reviewer** com
persona definida, findings estruturados com severidade formal, contexto
além do diff, security como primeira classe, source of truth discipline,
formato para no-findings, checks framework-specific, anti-padrões,
depth tiers, e output contract padronizado.

O `code-review.md` atual tem 150 linhas e é funcional mas genérico —
falta profundidade em áreas que pesquisas 2025-2026 mostram serem
críticas para agentes de code review.

## Pesquisa de Referência (resumo)

Pesquisa realizada em 6 fontes primárias sobre code review agents (2025-2026):

1. **Hire AI Staffs (Mar 2026)**: 5 boas práticas — combinar static analysis
   com LLM reasoning, construir entendimento contextual, tornar cada comentário
   acionável, integrar security scanning, aprender com feedback
   → URL: https://www.hireaistaffs.com/blog/best-ai-code-review-agents
2. **Refacto (Abr 2026)**: Anti-padrões — comentários vagos, bloquear sem
   justificativa, não distinguir blocking vs non-blocking, falta de contexto
   arquitetural
   → URL: https://refacto.ai/blog/code-review-best-practices-the-2026-playbook/
3. **Agent Shelf (Abr 2026)**: Agentes de review 2026 — framework awareness,
   severity classification, structured output
   → URL: https://www.agentshelf.dev/blog/ai-agents-for-code-review
4. **Microsoft hve-core**: Multi-perspectiva — Functional, Standards,
   Accessibility, Security, Readiness; severity taxonomy; depth tiers;
   context bootstrap
   → URL: https://github.com/microsoft/hve-core (skill:
   `.github/skills/coding-standards/code-review`) · docs:
   https://microsoft.github.io/hve-core/docs/agents/code-review/
5. **ribrewguy/structured-code-review**: 8-field preamble, severity tags,
   source of truth discipline, no-findings format
   → URL: https://github.com/ribrewguy/agent-skills (skill:
   `plugins/structured-code-review`) · página da skill:
   https://ribrewguy.github.io/agent-skills/skills/structured-code-review
6. **Angensi (Jul 2026)**: Security-first scanning, framework awareness,
   severity classification obrigatória
   → URL: https://www.agensi.io/learn/best-code-review-skills-ai-agents
   (nome correto da fonte: **Agensi**, agensi.io)

### Padrões-chave que se aplicam ao code-review.md

| Padrão | Fonte | Gap no code-review.md atual |
|--------|-------|-----------------------------|
| **Senior reviewer persona** | Angensi, Refacto | Persona genérica ("Revisa código") |
| **Severity taxonomy formal** | Microsoft, Angensi | Seções Críticos/Importantes/Sugestões sem severity |
| **Context gathering além do diff** | Hire AI Staffs | Não coleta arquivos relacionados |
| **Security como primeira classe** | Hire AI Staffs, Angensi | Security não é concern obrigatório |
| **Source of truth discipline** | ribrewguy | Cada finding não cita o que está verificando |
| **No-findings format** | ribrewguy | Sem formato para quando não há issues |
| **Framework-specific checks** | Angensi, Agent Shelf | Checks genéricos sem framework awareness |
| **Anti-padrões do reviewer** | Refacto | Sem anti-padrões documentados |
| **Depth tiers** | Microsoft | Sem níveis de profundidade |
| **Output contract padronizado** | ribrewguy, Angensi | Output por seções sem formato por-finding |

## Escopo

- **Dentro**: Alterar `.config/opencode/agents/code-review.md` (150 linhas → ~300-350 linhas estimadas)
- **Fora**: Não alterar skills, outros agentes, nem AGENTS.md

## Assumptions

1. O `code-review.md` é um agente subagent que recebe diffs via Task tool
2. O `task-build` já define contratos de output para code-review (step 6b, 6e)
3. As skills `code-reviewer`, `staff-engineer-review`, `security-reviewer` já
   existem e são carregadas como obrigatórias — as melhorias são no agente,
   não nas skills
4. O formato de output do code-review (Aprovado/Aprovação condicional/Precisa
   de ajustes) definido pelo task-build NÃO será alterado — apenas o DETALHE
   do relatório será enriquecido
5. Não há plano anterior para esta tarefa específica
6. As referências a skills existentes (code-reviewer, staff-engineer-review,
   security-reviewer) são complementares — o agente orquestra, as skills
   fornecem expertise

## Dependências

- **Pré-requisitos**: Nenhuma — todas as mudanças são em arquivo único
- **Dependência C2 ↔ I1/I2**: I1 (Source of truth) e I2 (No-findings format)
  expandem o template de findings criado por C2 — devem ser implementadas
  APÓS C2 estar aplicada. As demais tasks são independentes entre si.
- **Ordem**: As 10 tasks seguem a estrutura do arquivo (topo → workflow → regras).
  Recomenda-se a ordem numérica pois cada task constrói sobre as anteriores.

## Tasks

### Críticos

- [x] **C1. Persona de Senior Reviewer (linha 2 + linhas 32-35)**

  **Seção**: Atualizar a `description` do frontmatter (linha 2) e substituir
  as linhas 32-35 (intro genérica) por persona definida

  **Mudança**: Duas alterações complementares:

  **a) Frontmatter (linha 2)** — atualizar a description:

  De:

  ```yaml
  description: "Revisa código pós-implementação — qualidade, skills dinâmicas, plano vs execução"
  ```

  Para:

  ```yaml
  description: "Senior engineer conducting thorough, constructive code reviews — severity taxonomy, security scanning, context beyond the diff"
  ```

  **b) Intro (linhas 32-35)** — substituir:

  ```
  # Code Review Agent

  Revisa o diff de código após implementação. **Triangula** Plano × Skills × Código.
  Nunca modifica arquivos — apenas reporta.
  ```

  Por:

  ```
  # Code Review Agent

  Senior engineer conducting thorough, constructive code reviews. **Triangula**
  Plano × Skills × Código. Nunca modifica arquivos — apenas reporta.

  ## Persona

  - **Estilo**: Direto, específico, acionável — cada comentário tem o quê/porquê/como
  - **Prioridade**: Bugs e segurança primeiro, depois qualidade, depois estilo
  - **Tom**: Construtivo e respeitoso — reconhece boa Implementação antes de criticar
  - **Lente**: Lê como engenheiro sênior que precisa aprovar para production
  - **Contexto**: Entende o sistema além do diff — considera impacto em módulos vizinhos
  ```

  **Motivação**: "The reviewer persona determines the quality of feedback.
  A generic 'reviews code' persona produces generic feedback." (Angensi 2026,
  Refacto 2026). A description do frontmatter deve refletir a mesma persona —
  é ela que o opencode usa para roteamento/matching do subagente.

  **Acceptance**: Description do frontmatter (linha 2) atualizada para a nova
  persona; Seção "Persona" existe com 5 características documentadas;
  tom construtivo e específico; referência a impacto além do diff

  **Verify**:
  - Run: `grep -n "Senior engineer conducting" .config/opencode/agents/code-review.md`
  - Expected: retorna a linha 2 (frontmatter) E a intro (persona)
  - Run: `grep -n "Persona\|Estilo\|Prioridade\|Tom\|Lente\|Contexto" .config/opencode/agents/code-review.md`
  - Expected: deve retornar a nova seção com 5+ campos

  **Files**: `.config/opencode/agents/code-review.md` (linha 2 → atualizar description; linhas 32-35 → substituir por ~12 linhas)
  **Complexidade**: Baixa

---

- [x] **C2. Structured Findings com Severity Formal (step 6, linhas 114-143)**

  **Seção**: Substituir o template de relatório atual (linhas 114-143) por
  formato por-finding com severity taxonomy

  **Mudança**: O output do code-review DEVE seguir este formato exato:

  ```
  ## Resumo

  | Métrica | Valor |
  |---------|-------|
  | Arquivos revisados | {N} |
  | Skills obrigatórias | {lista} |
  | Skills dinâmicas | {lista} |
  | Planos encontrados | {lista ou "nenhum"} |
  | Findings | {Critical: N} · {High: N} · {Medium: N} · {Low: N} |
  | Veredito | **Aprovado** / **Aprovação condicional** / **Precisa de ajustes** |

  ## Triangulação Plano × Skills × Código

  - Plano previa: {X}
  - Skills recomendam: {Y}
  - Implementado: {Z}
  - Divergências: {lista ou "nenhuma"}

  ## Qualidade

  | Check | Comando | Resultado |
  |-------|---------|-----------|
  | {check 1} | `{comando}` | ✅ PASS / ❌ FAIL |
  | {check 2} | `{comando}` | ✅ PASS / ❌ FAIL |

  ## Findings

  ### FIND-001: {título curto}
  - **Severity**: `Critical` | `High` | `Medium` | `Low`
  - **File**: `path/to/file.ext`, line {N}
  - **Problem**: {o que está errado — específico, não genérico}
  - **Why it matters**: {impacto em production / segurança / manutenibilidade}
  - **Source of truth**: {o que está verificando — regra, padrão, convenção, spec}
  - **Proposed fix**: {código ou passo concreto para corrigir}

  ### FIND-002: {título curto}
  ...

  ## Positivos

  {padrões bem seguidos — elogios específicos com file:line}

  ## Perguntas para o Autor

  {clarificações necessárias — apenas se houver ambiguidade}

  ## Veredito

  **Aprovado** | **Aprovação condicional** | **Precisa de ajustes**

  {motivo do veredito em 1-2 frases}
  ```

  **Severity taxonomy**:

  | Severity | Critério | Ação |
  |----------|----------|------|
  | `Critical` | Bug que causa data loss, security vulnerability, crash em production | MUST fix antes de merge |
  | `High` | Bug funcional, performance degradation significativa, design flaw | SHOULD fix antes de merge |
  | `Medium` | Code smell, falta de testes, naming inconsistente | SHOULD fix — pode ser follow-up |
  | `Low` | Estilo, sugestões de melhoria, oportunidade de refactor | Nice to have |

  **Motivação**: "Each finding must have severity + file:line + Problem/Why/Source
  of truth/Proposed fix. No vague comments allowed." (ribrewguy 2026, Microsoft hve-core)

  **Acceptance**: Template de findings existe com 6 campos obrigatórios;
  severity taxonomy formal com 4 níveis e critérios; tabela de qualidade;
  veredito com 3 opções preservadas (compatível com task-build)

  **Verify**:
  - Run: `grep -n "FIND-\|Severity\|Source of truth\|Proposed fix\|Critical.*High.*Medium.*Low" .config/opencode/agents/code-review.md`
  - Expected: deve retornar template de findings com severity taxonomy

  **Files**: `.config/opencode/agents/code-review.md` (linhas 114-143 → substituir por ~55 linhas)
  **Complexidade**: Alta

---

- [x] **C3. Context Gathering — Além do Diff (nova seção após step 2)**

  **Seção**: Nova subseção "3. Contexto além do diff" (renumere steps 3-6
  para 4-7)

  **Mudança**: ANTES de revisar o diff, o code-review DEVE coletar contexto:

  ```
  ### 3. Contexto além do diff

  Antes de analisar o diff, o code-review DEVE:

  1. **Ler arquivos relacionados** — para cada arquivo no diff, identificar
     e ler imports/dependências que são afetados pela mudança
  2. **Verificar testes existentes** — localizar e ler testes que cobrem
     os arquivos modificados (usar grep por nome do módulo/teste)
  3. **Convenções do codebase** — identificar padrões de naming, error
     handling, imports, organização (ler 2-3 arquivos similares)
  4. **Specs e ADRs** — verificar se há decisões arquiteturais relevantes
     em `docs/decisions/` ou `docs/` para os módulos afetados
  5. **Impact scope** — mapear quais outros módulos/serviços são afetados
     indiretamente pelas mudanças

  > **Motivação**: "Build contextual understanding beyond the diff — consider
  > impact on adjacent modules, existing tests, and architectural decisions."
  > (Hire AI Staffs 2026)
  ```

  **Acceptance**: Nova subseção "3. Contexto além do diff" existe com 5 passos
  documentados; passo 1 menciona "imports/dependências"; passo 2 menciona
  "testes existentes"; passo 5 menciona "impacto indireto"

  **Verify**:
  - Run: `grep -n "Contexto além do diff\|arquivos relacionados\|testes existentes\|impact.*indireto" .config/opencode/agents/code-review.md`
  - Expected: deve retornar a nova subseção com 5 passos

  **Files**: `.config/opencode/agents/code-review.md` (após linha 53 → inserir ~20 linhas; renumerar steps 3-6 para 4-7)
  **Complexidade**: Média

---

- [x] **C4. Security como Concern de Primeira Classe (novo step)**

  **Seção**: Nova subseção "5b. Security Scan" (após quality checks, antes
  da revisão por skill)

  **Mudança**: Security scanning DEVE ser executado como passo dedicado,
  não apenas como item dentro da revisão:

  ```
  ### 5b. Security Scan

  Para cada arquivo no diff, verificar OWASP Top 10 e padrões de segurança:

  **Checks obrigatórios**:
  - SQL injection: queries com string interpolation → `parameterized queries`
  - XSS: innerHTML, dangerouslySetInnerHTML, markups sem escape
  - Hardcoded secrets: tokens, passwords, API keys no código
  - Auth bypass: endpoints sem autenticação, role checks ausentes
  - Input validation: dados externos sem sanitização
  - Crypto: algoritmos fracos (MD5, SHA1 para passwords), IVs reutilizados

  **Se encontrar vulnerabilidade**:
  - Classificar como `Critical` ou `High` (nunca `Low` para security)
  - Incluir referência OWASP/CWE: "OWASP A03:2021", "CWE-89"
  - Proposed fix DEVE incluir código seguro como exemplo

  **Skills de segurança**: Carregar `security-reviewer` se não estiver
  carregada (`api-security-best-practices` já é obrigatória no step 1 —
  não recarregar)

  > **Motivação**: "Integrate security scanning as a first-class concern —
  > don't treat it as an afterthought." (Hire AI Staffs 2026, Angensi 2026)
  ```

  **Acceptance**: Subseção "5b. Security Scan" existe; 6 checks obrigatórios
  documentados; regra de classificação (nunca Low para security); referência
  a OWASP/CWE obrigatória em findings de segurança; instrução de skills
  carrega apenas `security-reviewer` condicionalmente

  **Verify**:
  - Run: `grep -n "Security Scan\|OWASP\|CWE\|SQL injection\|hardcoded secrets" .config/opencode/agents/code-review.md`
  - Expected: deve retornar subseção com checks de segurança
  - Run: `grep -n "security-reviewer.*se não estiver\|já é obrigatória no step 1" .config/opencode/agents/code-review.md`
  - Expected: instrução correta de carregamento de skill (sem duplicar api-security-best-practices)

  **Files**: `.config/opencode/agents/code-review.md` (após linha ~108 → inserir ~22 linhas)
  **Complexidade**: Média

---

### Importantes

- [x] **I1. Source of Truth Discipline (no campo "Source of truth" de C2)**

  **Dependência**: requer C2 aplicado primeiro (expande o template de C2)

  **Seção**: Dentro do template de findings (C2), expandir o campo
  "Source of truth" com instruções explícitas

  **Mudança**: Adicionar instrução ao campo "Source of truth" do finding:

  ```
  - **Source of truth**: {o que está verificando — DEVE citar uma das opções:
    regra específica do codebase, convenção documentada, spec/ADR existente,
    padrão da tecnologia, ou boas práticas gerais. Se não houver source
    of truth específico, marcar como "Boas práticas gerais" e sugerir
    criar convenção documentada}
  ```

  **Motivação**: "Source of truth discipline: every finding must cite what
  it's verifying against. 'This looks wrong' is not a finding — 'This violates
  the error handling convention in src/lib/errors.ts' is." (ribrewguy 2026)

  **Acceptance**: Campo "Source of truth" tem instrução explícita de citar
  fonte; 4 opções de source listadas; regra para quando não há convenção

  **Verify**:
  - Run: `grep -n "Source of truth.*DEVE\|Source of truth.*regra\|Source of truth.*convenção" .config/opencode/agents/code-review.md`
  - Expected: deve retornar instrução de source of truth

  **Files**: `.config/opencode/agents/code-review.md` (dentro do template C2 → expandir ~8 linhas)
  **Complexidade**: Baixa

---

- [x] **I2. No-Findings Format (no template de C2)**

  **Dependência**: requer C2 aplicado primeiro (complementa o template de C2)

  **Seção**: Adicionar ao final do template de findings (C2) formato para
  quando não houver issues

  **Mudança**: Inserir após os findings:

  ```
  ### Sem findings

  Se NENHUM finding for identificado (nenhum Critical, High, Medium ou Low):

  ```
  ## Findings

  Nenhum finding identificado.

  ## Residual Risks

  - {Risco 1: descrição — por que não é finding mas vale notar}
  - {Risco 2: descrição}

  ## Gaps

  - {Gap 1: o que não pôde ser verificado e por quê}
  - {Gap 2: limitação da revisão atual}
  ```

  **Motivação**: "No-findings format must include Residual Risks and Gaps —
  absence of findings doesn't mean absence of risk." (ribrewguy 2026)

  **Acceptance**: Formato "Sem findings" existe com 3 campos: Findings,
  Residual Risks, Gaps; cada um com instrução

  **Verify**:
  - Run: `grep -n "Sem findings\|Residual Risks\|Gaps" .config/opencode/agents/code-review.md`
  - Expected: deve retornar formato para no-findings

  **Files**: `.config/opencode/agents/code-review.md` (após template C2 → inserir ~12 linhas)
  **Complexidade**: Baixa

---

- [x] **I3. Framework-Specific Checks (expandir step 4, linhas 87-108)**

  **Seção**: Expandir a seção "Quality Checks (auto-detect)" com
  checks específicos por framework

  **Mudança**: Adicionar após cada bloco de detecção de stack:

  **Python** — adicionar:
  ```
  - Type safety: `mypy .` ou `pyright` (se configurado)
  - Security: `bandit -r ./src` (se instalado)
  - Dependency audit: `pip-audit` (se instalado)
  ```

  **Node.js** — adicionar:
  ```
  - Type safety: `tsc --noEmit` (se tsconfig.json existe)
  - Security: `npm audit --audit-level=moderate`
  - Bundle analysis: `npm run build -- --analyze` (se configurado)
  ```

  **Genérico** — adicionar bloco:
  ```
  **Shell scripts** (`*.sh` existe no diff):
  - Lint: `shellcheck *.sh` (se instalado)

  **Docker** (`Dockerfile` ou `docker-compose.yml` existe no diff):
  - Lint: `hadolint Dockerfile` (se instalado)
  - Security: `trivy fs .` (se instalado)
  ```

  **Motivação**: "Framework-aware review catches framework-specific issues
  that generic checks miss." (Angensi 2026, Agent Shelf 2026)

  **Acceptance**: Cada stack (Python, Node.js) tem 3+ checks adicionais;
  blocos genéricos para Shell e Docker existem; todos os checks extras são
  "se instalado" (não obrigatórios)

  **Verify**:
  - Run: `grep -n "mypy\|bandit\|tsc --noEmit\|npm audit\|shellcheck\|hadolint" .config/opencode/agents/code-review.md`
  - Expected: deve retornar ≥5 resultados (checks extras)

  **Files**: `.config/opencode/agents/code-review.md` (linhas 87-108 → expandir ~20 linhas)
  **Complexidade**: Média

---

- [x] **I4. Anti-padrões do Reviewer (nova seção nas Regras)**

  **Seção**: Nova subseção "### Anti-padrões de Review" na seção "Regras"

  **Mudança**: Listar anti-padrões comuns de code review e como evitá-los:

  ```
  ### Anti-padrões de Review

  | Anti-padrão | Consequência | Correção |
  |---|---|---|
  | Comentário vago ("needs work", "clean this up") | Dev não entende o que mudar | Sempre especificar: o quê/porquê/como |
  | Bloquear sem justificativa | Frustração, perda de confiança | Citar source of truth para cada finding |
  | Não distinguir blocking vs non-blocking | Dev trata tudo como urgente | Usar severity formal: Critical/High = blocking |
  | Nitpick de estilo quando linter existe | Desperdício de tempo | Verificar se linter cobre antes de reportar |
  | Ignorar contexto arquitetural | Feedback incorreto ou irrelevante | Seguir step 3 (contexto além do diff) |
  | Não elogiar boa implementação | Review percebido como negativo | Sempre incluir seção "Positivos" |
  | Reviewar sem entender o "porquê" | Sugestões que contradizem decisões | Ler specs/ADRs antes de revisar |
  | Pular security scan | Vulnerabilidades passam despercebidas | Executar step 5b sempre |
  | Finding sem localização exata | Dev gasta tempo procurando | Sempre incluir file:line em cada finding |
  | Review superficial em código complexo | Bugs em lógica passam | Aumentar profundidade para código crítico |
  ```

  **Motivação**: "Common anti-patterns: vague comments, blocking without
  justification, not distinguishing blocking vs non-blocking, lack of
  architectural context." (Refacto 2026)

  **Acceptance**: Tabela de anti-padrões existe com 10+ entradas; cada uma
  com Anti-padrão | Consequência | Correção; referência a seções correspondentes

  **Verify**:
  - Run: `grep -n "Anti-padrões de Review\|needs work\|Bloquear sem\|nitpick\|security scan" .config/opencode/agents/code-review.md`
  - Expected: deve retornar tabela com anti-padrões

  **Files**: `.config/opencode/agents/code-review.md` (após "Regras" → inserir ~18 linhas)
  **Complexidade**: Baixa

---

- [x] **I5. Depth Tiers (nova seção no workflow)**

  **Seção**: Nova subseção "### 1a. Depth Tier Selection" (antes de carregar
  skills obrigatórias)

  **Mudança**: Definir 3 níveis de profundidade de review:

  ```
  ### 1a. Depth Tier Selection

  O code-review DEVE selecionar o depth tier ANTES de iniciar a revisão:

  | Tier | Critério | Profundidade | Tempo estimado |
  |------|----------|-------------|----------------|
  | **Basic** | 1-2 arquivos, fix pontual, sem mudança arquitetural | Checklists superficiais, security scan mínimo | 1-2 min |
  | **Standard** | 3-5 arquivos, feature modesta, refatoração limitada | Review completo, contexto parcial, todos os checks | 2-4 min |
  | **Comprehensive** | 6+ arquivos, feature complexa, mudança arquitetural | Review profundo, contexto completo, todos os checks + framework-specific | 3-5 min |

  **Como selecionar**:
  - Se `task-build` especificou o tier → usar o indicado
  - Se não especificou → auto-detectar baseado no tamanho do diff e complexidade
  - Em caso de dúvida → usar **Standard** (mais seguro que Basic, mais rápido que Comprehensive)

  **Restrição de timeout (task-build)**: O task-build define timeout de
  **5 min** para code-review de código (step 6b) e **10 min** para revisão
  de plano (step 4b). Os tempos estimados acima foram calibrados para caber
  no timeout de código. Se um review abrangente ameaçar estourar o timeout,
  priorizar findings Critical/High e registrar o que não foi verificado na
  seção Gaps (ver I2) — nunca estourar o timeout silenciosamente.

  **O que muda por tier**:

  | Aspecto | Basic | Standard | Comprehensive |
  |---------|-------|----------|---------------|
  | Context gathering | Mínimo | Parcial (imports + testes) | Completo (imports + testes + specs + impact) |
  | Security scan | OWASP rápido | OWASP completo | OWASP completo + dependency audit |
  | Framework checks | Pular | Rodar detectados | Rodar todos detectados |
  | Source of truth | Obrigatório | Obrigatório | Obrigatório |
  | Findings detalhados | Apenas Critical/High | Todos | Todos + sugestões arquiteturais |

  > **Motivação**: "Depth tiers allow the reviewer to match effort to risk —
  > don't spend 10 minutes reviewing a typo fix." (Microsoft hve-core)
  ```

  **Acceptance**: Subseção "1a. Depth Tier Selection" existe com 3 tiers
  (Basic/Standard/Comprehensive); tabela de critérios; instrução de seleção;
  restrição de timeout do task-build documentada; tabela de "o que muda por
  tier" com 5 aspectos

  **Verify**:
  - Run: `grep -n "Depth Tier\|Basic.*Standard.*Comprehensive\|auto-detectar\|context.*Parcial\|context.*Completo" .config/opencode/agents/code-review.md`
  - Expected: deve retornar subseção com 3 tiers e tabelas
  - Run: `grep -n "timeout" .config/opencode/agents/code-review.md`
  - Expected: deve retornar a restrição de timeout do task-build

  **Files**: `.config/opencode/agents/code-review.md` (após linha 30 → inserir ~30 linhas)
  **Complexidade**: Média

---

- [x] **I6. Output Contract Padronizado (expandir regras)**

  **Seção**: Nova subseção "### Contrato de Output" na seção "Regras"

  **Mudança**: Definir o contrato de output do code-review para o task-build:

  ```
  ### Contrato de Output

  O code-review DEVE retornar output compatível com o task-build:

  **Para code-review de código** (steps 6b/6e do task-build):
  - ✅ Sucesso: veredito + detalhes do relatório
    - `"Aprovado"` — nenhum Critical ou High
    - `"Aprovação condicional"` — apenas Medium/Low pendentes
    - `"Precisa de ajustes"` — há Critical ou High não resolvidos
  - ❌ Erro: `"Falha ao revisar task {id}: {motivo}"`

  **Para code-review de plano** (step 4b do task-build):
  - ✅ Sucesso: veredito `[OKAY]` ou `[REJECT]` + motivos
  - ❌ Erro: `"Falha ao revisar plano: {motivo}"`

  **Regras de veredito**:
  - `Critical` ou `High` não resolvido → SEMPRE "Precisa de ajustes"
  - Apenas `Medium` e `Low` pendentes → "Aprovação condicional"
  - Nenhum finding → "Aprovado"
  - Quality check falhou → "Precisa de ajustes" (independente de findings)
  ```

  **Motivação**: "Telling the agent how to format its answer makes the result
  usable downstream — by you, by a script, or by the next link in a chain."
  (AgentsCamp 2026)

  **Acceptance**: Subseção "Contrato de Output" existe; 3 vereditos com regras;
  mapeamento severity → veredito documentado; compatível com task-build

  **Verify**:
  - Run: `grep -n "Contrato de Output\|Critical.*High.*Precisa\|Medium.*Low.*Condicional\|Nenhum finding.*Aprovado" .config/opencode/agents/code-review.md`
  - Expected: deve retornar contrato de output

  **Files**: `.config/opencode/agents/code-review.md` (na seção "Regras" → inserir ~18 linhas)
  **Complexidade**: Baixa

---

## Riscos

- **Expansão do tamanho**: code-review.md vai de ~150 para ~300-350 linhas.
  Risco baixo — o task-build.md já tem 619 linhas e funciona bem.
  → Mitigação: manter seções concisas; usar tabelas em vez de parágrafos

- **Conflito com contratos do task-build**: task-build.md já define
  contratos de output para code-review (Aprovado/Aprovação condicional/
  Precisa de ajustes). Risco baixo — o output contract (I6) reforça e
  detalha esses mesmos contratos sem alterá-los.
  → Mitigação: I6 referencia task-build explicitamente; mantém os 3
  vereditos idênticos

- **Context gathering pode ser lento**: Ler arquivos além do diff consome
  tempo. Risco médio — pode ultrapassar timeout de 5 min (código).
  → Mitigação: Depth tiers (I5) controlam profundidade; Comprehensive
  calibrado para 3-5 min (dentro do timeout do task-build); Basic pula
  context gathering extenso

- **Security scan pode gerar falsos positivos**: Bandit/npm audit podem
  reportar issues que não são reais no contexto. Risco baixo.
  → Mitigação: security findings são classificados pelo reviewer (não
  automaticamente); "Source of truth" garante validação manual

- **Muitos anti-padrões podem confundir**: 10+ anti-padrões em tabela
  podem ser overwhelming. Risco baixo.
  → Mitigação: tabela é referência — o reviewer não precisa checar cada
  um; os anti-padrões mais críticos estão no topo

## Ordem de Implementação

Recomendada (constrói de baixo para cima — persona primeiro, depois
estrutura, depois refinamentos):

1. **C1** (Persona) — fundação para todos os outros passos
2. **C3** (Context gathering) — define ANTES de revisar
3. **C4** (Security scan) — adiciona concern de primeira classe
4. **C2** (Structured findings) — template de output principal
5. **I5** (Depth tiers) — controla profundidade do review
6. **I1** (Source of truth) — enriquece findings de C2
7. **I2** (No-findings format) — complementa findings de C2
8. **I3** (Framework checks) — enriquece quality checks
9. **I4** (Anti-padrões) — previne comportamentos indesejados
10. **I6** (Output contract) — padroniza comunicação com task-build

**Nota sobre deslocamento de linhas**: As referências de linha das tasks
(ex: C2 "linhas 114-143") valem para o arquivo ORIGINAL. Após C1 (que insere
~8 linhas líquidas), usar **grep para localizar seções** em vez de confiar
nos números de linha — todos os comandos Verify das tasks já usam grep
para esse fim.

**Nota**: Embora recomendadas nessa ordem, as tasks são independentes e podem
ser implementadas em paralelo — EXCETO I1/I2, que DEPENDEM de C2 (ambas
refinam o template de findings criado por C2; ver seção Dependências).

## Dependências

- **Pré-requisitos**: Nenhuma (tasks editam apenas `code-review.md`)
- **Ordem**: C1 → C3 → C4 → C2 → I5 → I1 → I2 → I3 → I4 → I6
  (recomendada, mas independentes)
- **C2 ↔ I1/I2**: I1 e I2 DEPENDEM de C2 — ambas editam o template de
  findings que só passa a existir após C2 ser aplicada. Implementar C2
  antes de I1/I2 (a ordem recomendada já reflete isso). Demais tasks:
  independentes entre si.
- **Relação com task-build.md**: code-review.md NÃO modifica contratos
  do task-build; I6 reforça os mesmos contratos com detalhes. I5 respeita
  o timeout de 5 min (código) definido na tabela Timeout do task-build.

## Verificação Final

```bash
# Verificar que todas as novas seções foram criadas
grep -n "Persona\|Contexto além\|Security Scan\|FIND-\|Source of truth\|Depth Tier\|Anti-padrões de Review\|Contrato de Output\|Sem findings\|Residual Risks" \
  .config/opencode/agents/code-review.md

# Verificar integridade do frontmatter (delimitadores --- intactos;
# apenas a description da linha 2 muda — ver C1a)
head -30 .config/opencode/agents/code-review.md | grep "^---$" | wc -l
# Deve retornar 2 (abertura e fechamento)

# Verificar description atualizada do frontmatter (C1a)
grep -n "Senior engineer conducting" .config/opencode/agents/code-review.md
# Deve retornar a linha 2 (frontmatter) e a intro (persona)

# Verificar severity taxonomy
grep -n "Critical.*High.*Medium.*Low\|severity.*taxonomy" \
  .config/opencode/agents/code-review.md

# Verificar framework-specific checks
grep -n "mypy\|bandit\|tsc --noEmit\|npm audit\|shellcheck\|hadolint" \
  .config/opencode/agents/code-review.md

# Verificar anti-padrões
grep -c "Anti-padrão\|anti-padrão" .config/opencode/agents/code-review.md
# Deve retornar ≥3 (incluindo cabeçalho)

# Verificar depth tiers
grep -n "Basic.*Standard.*Comprehensive" .config/opencode/agents/code-review.md

# Verificar restrição de timeout (I5)
grep -n "timeout" .config/opencode/agents/code-review.md

# Verificar output contract
grep -n "Contrato de Output\|Precisa de ajustes.*Critical\|Aprovação condicional.*Medium" \
  .config/opencode/agents/code-review.md

# Contar linhas totais (deve ser > 280 e < 380)
wc -l .config/opencode/agents/code-review.md

# Verificar compatibilidade com task-build
grep -n "Aprovado\|Aprovação condicional\|Precisa de ajustes" \
  .config/opencode/agents/code-review.md | head -5
```

## Teste Funcional

### Cenário 1: Review de arquivo com vulnerabilidades deliberadas

**Objetivo**: Validar que o code-review atualizado produz findings
estruturados com severity formal, security scan e source of truth
(cobre C1, C2, C4, I1).

**Setup** (arquivo de teste FORA do repo, em /tmp):

```bash
mkdir -p /tmp/opencode/cr-test && cat > /tmp/opencode/cr-test/payment.py <<'EOF'
import sqlite3

API_KEY = "sk-live-51H7xqExampleKeyDoNotUse"  # hardcoded secret

def get_user(user_id):
    conn = sqlite3.connect("app.db")
    # SQL injection via string interpolation
    return conn.execute(f"SELECT * FROM users WHERE id = {user_id}").fetchall()
EOF
```

**Execução**: Invocar o subagente `code-review` com o diff do arquivo acima
(sem tier especificado — deve auto-detectar Basic ou Standard).

**Verificações esperadas no relatório retornado**:

1. Tabela Resumo com contagem de findings por severity
2. SQL injection classificado como `Critical` com referência
   OWASP A03:2021 / CWE-89
3. Hardcoded secret classificado como `Critical` ou `High` com
   referência CWE-798
4. Cada finding tem os 6 campos (Severity/File/Problem/Why it matters/
   Source of truth/Proposed fix)
5. Veredito = **"Precisa de ajustes"** (há Critical não resolvido)
6. Seção Positivos presente (mesmo com findings)

**Critério de aprovação**: Os 6 itens presentes. Se o relatório vier no
formato antigo (seções Críticos/Importantes/Sugestões sem IDs FIND-),
a task C2 não foi aplicada corretamente.

**Cleanup**: `rm -rf /tmp/opencode/cr-test`

### Cenário 2: Mudança trivial — depth tier + no-findings format

**Objetivo**: Validar seleção de tier Basic e o formato no-findings
(cobre I5, I2).

**Execução**: Invocar o `code-review` sobre uma mudança trivial (ex:
correção de typo em comentário de `shell/aliases.sh`).

**Verificações esperadas**:

1. Tier selecionado = **Basic** (1-2 arquivos, fix pontual)
2. Se nenhum finding: seção Findings com "Nenhum finding identificado"
   + **Residual Risks** + **Gaps** preenchidos (nunca um "looks good" vazio)
3. Tempo total dentro do estimado para Basic (1-2 min)

**Critério de aprovação**: Tier correto + formato no-findings completo.

## Referências

- Hire AI Staffs (2026): 5 Best Practices for Building an AI Code Review Agent
  https://www.hireaistaffs.com/blog/best-ai-code-review-agents
- Refacto (2026): Code Review Best Practices: The 2026 Playbook
  https://refacto.ai/blog/code-review-best-practices-the-2026-playbook/
- Agent Shelf (2026): Best AI Agents for Code Review in 2026
  https://www.agentshelf.dev/blog/ai-agents-for-code-review
- Microsoft hve-core: Multi-perspective code review with severity taxonomy
  https://github.com/microsoft/hve-core · docs:
  https://microsoft.github.io/hve-core/docs/agents/code-review/
- ribrewguy/structured-code-review: 8-field preamble, source of truth discipline
  https://github.com/ribrewguy/agent-skills · página da skill:
  https://ribrewguy.github.io/agent-skills/skills/structured-code-review
- Agensi (2026): Best Code Review Skills for AI Coding Agents
  https://www.agensi.io/learn/best-code-review-skills-ai-agents
- Anthropic (2024-2026): Self-repair via structured reflection

## Histórico de Revisão

- **v1 (20/08/2026:16:57)**: Plano inicial criado — 10 tasks (C1-C4, I1-I6),
  pesquisa em 6 fontes primárias, riscos, ordem de implementação, verificação final.
- **v2 (20/08/2026:18:28)**: Refinamento a partir do code review do plano —
  aplicadas 7 sugestões: URLs das fontes primárias (Pesquisa + Referências);
  description do frontmatter incluída em C1; tier Comprehensive recalibrado
  para 3-5 min + restrição de timeout do task-build documentada em I5;
  instrução de skills de segurança corrigida em C4 (carregar apenas
  `security-reviewer` condicionalmente); dependência C2↔I1/I2 documentada
  nas seções Dependências e nas tasks I1/I2; nota sobre deslocamento de
  linhas adicionada à Ordem de Implementação; seção Teste Funcional criada
  com 2 cenários. Estrutura geral e numeração das tasks preservadas.
