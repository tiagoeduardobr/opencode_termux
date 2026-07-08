# Plano: Revisão Completa de Skills do repositório opencode_termux

## Metadata

- **Última atualização:** 07/07/2026:00:37
- **Status:** Plano corrigido conforme recomendações do code-review

## Objetivo

Realizar uma auditoria completa das 41 skills instaladas, atualizar dependências, verificar integridade e identificar oportunidades de melhoria — priorizando estabilidade sobre novidades.

## Escopo

- **Dentro**: Atualizar plugin npm, auditar skills existentes, buscar novas skills upstream, verificar integridade, atualizar documentação
- **Fora**: Remover skills sem aprovação, modificar skills funcionais, alterar RBAC/permissions

## Assumptions

1. O repositório `synapse-ai-hub/opencode-skills` (66 skills) é a fonte upstream principal
2. As 41 skills atuais estão funcionando (nenhum erro de carregamento reportado)
3. O `@opencode-ai/plugin` 1.17.14 é compatível com as skills atuais
4. O device real (Termux/Ubuntu proot) não está acessível neste momento — validação será documentada para execução posterior
5. Skills de `parecer_descritivo` (design-system-patterns, design-tokens) permanecem no repositório

## Dependências

- **Pré-requisitos**: Acesso ao npm registry (para verificar versão latest), acesso ao GitHub (para buscar upstream skills)
- **Ordem**: Atualização npm → Auditoria → Busca → Integração → Documentação

---

## Tasks

### Fase 1: Atualização da Dependência npm

- [x] **TASK-01:** Atualizar `@opencode-ai/plugin` de 1.15.13 para 1.17.14 – Concluído em [06/07/2026:23:57]
  - Acceptance: `package.json` mostra `"@opencode-ai/plugin": "1.17.14"` e `package-lock.json` regenerado
  - Verification:
    - Run: `cat .config/opencode/package.json | grep -A2 -B2 "@opencode-ai/plugin"` e `npm ls @opencode-ai/plugin`
    - Expected: Versão "1.17.14" aparece no output; `npm ls` retorna sem erros
  - Files: `.config/opencode/package.json`, `.config/opencode/package-lock.json`
  - Complexidade: baixa

### Fase 2: Auditoria das Skills Existentes

- [x] **TASK-02:** Verificar integridade de todas as 41 skills (frontmatter válido) – Concluído em [07/07/2026:00:01]
  - Acceptance: Todas as 41 skills têm SKILL.md com frontmatter YAML válido (name, description)
  - Verification:
    - Run: `for d in .config/opencode/skills/*/; do head -1 "$d/SKILL.md"; done`
    - Expected: Todas as 41 linhas retornam `---`
  - Files: `.config/opencode/skills/*/SKILL.md` (41 arquivos)
  - Complexidade: baixa

- [x] **TASK-03:** Verificar sincronização entre `opencode.json` permission.skill e diretório de skills – Concluído em [07/07/2026:00:02]
  - Acceptance: Todas as 41 skills do diretório estão listadas em `opencode.json` permission.skill com `"allow"`
  - Verification:
    - Run: `ls .config/opencode/skills/ | wc -l` e `jq '.permission.skill | length' opencode.json`
    - Expected: Ambos retornam 41; comparação manual mostra correspondência
  - Files: `opencode.json`
  - Complexidade: baixa

- [x] **TASK-04:** Identificar skills com sobreposição funcional – Concluído em [07/07/2026:00:37]
  - Acceptance: Lista documentada de pares de skills com sobreposição, com recomendação para cada caso
  - Verification:
    - Run: `cat .opencode/plans/revisao-skills-sobreposicoes.md`
    - Expected: Arquivo existe com lista de sobreposições e recomendações
  - Files: `.opencode/plans/revisao-skills-sobreposicoes.md`
  - Complexidade: média

  **Sobreposições identificadas na análise preliminar:**
  | Skill A | Skill B | Sobreposição | Recomendação |
  |---------|---------|--------------|--------------|
  | `code-reviewer` | `staff-engineer-review` | Ambos revisam código | Manter ambos — `staff-engineer-review` é mais profundo/arquitetural |
  | `requesting-code-review` | `receiving-code-review` | Ambos sobre code review | Manter ambos — faces opostas do mesmo processo |
  | `writing-plans` | `spec-driven-development` | Ambos planejam | Manter ambos — `writing-plans` é mais específico para implementação |
  | `design-system-patterns` | `design-tokens` | Ambos sobre design systems | **UNIFICAR** — design-tokens é subconjunto de design-system-patterns |
  | `frontend-design` | `designing-frontend-interfaces` | Ambos sobre UI | **UNIFICAR** — são essencialmente a mesma skill |
  | `web-design-guidelines` | `designing-frontend-interfaces` | Ambos sobre web UI | Manter ambos — `guidelines` é compliance, `designing` é criação |

- [x] **TASK-05:** Verificar compatibilidade das skills com opencode 1.17.14 – Concluído em [07/07/2026:00:01]
  - Acceptance: Nenhuma skill usa campos frontmatter deprecated ou features removidas
  - Verification:
    - Run: `grep -l "deprecated:" .config/opencode/skills/*/SKILL.md || echo "Nenhum campo deprecated encontrado"`
    - Expected: Nenhum arquivo contém campos deprecated
  - Files: `.config/opencode/skills/*/SKILL.md`
  - Complexidade: média

### Fase 3: Busca de Novas Skills Upstream

- [x] **TASK-06:** Consultar repositório `synapse-ai-hub/opencode-skills` para identificar skills ausentes – Concluído em [07/07/2026:00:14]
  - Acceptance: Lista de skills do upstream que NÃO estão no repositório local, com justificativa para cada uma
  - Verification:
    - Run: `cat .opencode/plans/revisao-skills-upstream.md`
    - Expected: Arquivo existe com lista de skills ausentes e justificativas
  - Files: `.opencode/plans/revisao-skills-upstream.md`
  - Complexidade: média

  **Skills upstream identificadas que NÃO estão no repositório (análise preliminar):**
  - Linguagens: `go-expert`, `rust-expert`, `cpp-expert`, `csharp-expert`, `java-expert`, `php-expert`, `swift-expert`, `kotlin-expert`, `sql-expert`
  - Frameworks: `react-expert`, `nextjs-expert`, `vue-expert`, `angular-expert`, `nestjs-expert`, `django-expert`, `spring-boot-expert`, `laravel-expert`, `rails-expert`, `dotnet-expert`, `react-native-expert`, `flutter-expert`, `wordpress-expert`
  - Infra: `kubernetes-expert`, `terraform-engineer`, `devops-engineer`, `cloud-architect`, `sre-engineer`, `monitoring-expert`, `chaos-engineering`, `embedded-systems`
  - Qualidade: `api-design`, `graphql-expert`, `microservices-expert`, `security-reviewer`, `debugging-wizard`
  - Especializado: `salesforce-developer`, `shopify-expert`, `mcp-development`, `prompt-engineer`, `rag-architect`, `fine-tuning-expert`
  - Workflow: `feature-forge`, `architecture-designer`, `fullstack-guardian`

- [x] **TASK-07:** Avaliar quais novas skills seriam úteis para o contexto do repositório – Concluído em [07/07/2026:00:12]
  - Acceptance: Lista priorizada de skills recomendadas (máx. 10) com justificativa
  - Verification:
    - Run: `cat .opencode/plans/revisao-skills-recomendadas.md`
    - Expected: Arquivo existe com lista priorizada e casos de uso
  - Files: `.opencode/plans/revisao-skills-recomendadas.md`
  - Complexidade: média

  **Filtros de prioridade:**
  - Relevante para projetos Python/FastAPI (já usado)
  - Relevante para revisão de código e qualidade
  - Relevante para DevOps/infra (Termux, proot, Cloudflare)
  - NÃO relevante: skills de frameworks não utilizados (React, Vue, etc.)

- [x] **TASK-08:** Verificar se há versões atualizadas das skills existentes no upstream – Concluído em [07/07/2026:00:14]
  - Acceptance: Documentação de quais skills locais têm versão mais recente disponível
  - Verification:
    - Run: `cat .opencode/plans/revisao-skills-versoes.md`
    - Expected: Arquivo existe com comparação de versões
  - Files: `.opencode/plans/revisao-skills-versoes.md`
  - Complexidade: média

### Fase 4: Validação e Integração

- [x] **TASK-09:** Decidir quais novas skills instalar (após aprovação do usuário) – Concluído em [07/07/2026:15:18]
  - Acceptance: Lista final de skills a instalar aprovada pelo usuário
  - Verification:
    - Run: Usuário aprova via QUESTION TOOL ou mensagem direta
    - Expected: Resposta explícita de aprovação registrada
  - Files: N/A (decisão)
  - Complexidade: baixa

- [x] **TASK-10:** Instalar novas skills aprovadas (se houver) – Concluído em [07/07/2026:15:09]
  - Acceptance: Novas skills instaladas com SKILL.md válido e adicionadas ao `opencode.json` permission.skill
  - Verification:
    - Run: `ls .config/opencode/skills/ | grep -E "nova-skill|outra-skill"` e `jq '.permission.skill | keys' opencode.json`
    - Expected: Novas pastas aparecem no ls; novas chaves aparecem no JSON
  - Files: `.config/opencode/skills/<nova-skill>/SKILL.md`, `opencode.json`
  - Complexidade: média
  - **Nota:** Nomes corrigidos do upstream: `sql-pro` (não `sql-expert`) e `microservices-architect` (não `microservices-expert`)
  - Skills instaladas: devops-engineer, cloud-architect, sql-pro, sre-engineer, monitoring-expert, security-reviewer, debugging-wizard, architecture-designer, terraform-engineer, microservices-architect
  - Total: 51 skills (41 originais + 10 novas), todas com SKILL.md + references/

- [ ] **TASK-11:** Remover skills obsoletas (se aprovado pelo usuário)
  - Acceptance: Skills marcadas como obsoletas removidas do diretório e do `opencode.json`
  - Verification:
    - Run: `ls .config/opencode/skills/ | grep -E "skill-obsoleta|outra-obsoleta" || echo "Nenhuma skill obsoleta encontrada"` e `jq '.permission.skill | keys' opencode.json`
    - Expected: Nenhuma das skills obsoletas aparece no ls; chaves removidas do JSON
  - Files: `.config/opencode/skills/<skill-obsoleta>/`, `opencode.json`
  - Complexidade: baixa

### Fase 5: Documentação

- [x] **TASK-12:** Atualizar `AGENTS.md` se o número de skills mudar – Concluído em [07/07/2026:15:13]
  - Acceptance: Contagem de skills no AGENTS.md reflete o número real
  - Verification:
    - Run: `grep -c "skills" AGENTS.md` e `ls .config/opencode/skills/ | wc -l`
    - Expected: Números coincidem
  - Files: `AGENTS.md`
  - Complexidade: baixa

- [x] **TASK-13:** Atualizar `docs/SESSION_CONTEXT_20260618.md` com data da revisão – Concluído em [07/07/2026:15:13]
  - Acceptance: Seção "Mudanças Recentes" atualizada com data de hoje
  - Verification:
    - Run: `grep "06/07/2026" docs/SESSION_CONTEXT_20260618.md`
    - Expected: Entrada com data 06/07/2026 encontrada
  - Files: `docs/SESSION_CONTEXT_20260618.md`
  - Complexidade: baixa

- [x] **TASK-14:** Criar ADR se houver mudança arquitetural significativa – Concluído em [07/07/2026:15:13]
  - Acceptance: Se skills forem removidas/renomeadas, ADR documenta a decisão
  - Verification:
    - Run: `ls docs/decisions/ADR-0XX-*.md 2>/dev/null || echo "Nenhum ADR criado"`
    - Expected: Arquivo ADR existe se houve mudança; caso contrário, mensagem informativa
  - Files: `docs/decisions/ADR-0XX-*.md` (condicional)
  - Complexidade: baixa

---

## Riscos

| Risco | Mitigação |
|-------|-----------|
| Atualização npm quebra compatibilidade | Testar `npm ls` após update; manter rollback via git |
| Skills upstream incompatíveis com opencode 1.17.14 | Verificar frontmatter antes de instalar |
| Remoção acidental de skill usada | NÃO remover sem aprovação explícita do usuário |
| Skills novas conflitam com existentes | Verificar nomes duplicados antes de instalar |
| Device real não disponível para teste | Documentar comando de validação para execução posterior |

---

## Ordem de Implementação

1. **TASK-01** (atualização npm) — base para todas as outras
2. **TASK-02, 03, 05** (integridade) — podem rodar em paralelo
3. **TASK-04** (sobreposições) — requer análise manual
4. **TASK-06, 07, 08** (busca upstream) — podem rodar em paralelo
5. **TASK-09** (decisão do usuário) — gate antes de instalar/remover
6. **TASK-10, 11** (instalar/remover) — após aprovação
7. **TASK-12, 13, 14** (documentação) — último passo

---

## Verificação Final

Após todas as tasks:
- [x] `package.json` mostra versão 1.17.14
- [x] Todas as skills têm SKILL.md válido
- [x] `opencode.json` permission.skill sincronizado com diretório
- [x] AGENTS.md com contagem correta
- [x] SESSION_CONTEXT_20260618.md atualizado
- [x] Nenhum erro de formatação em skills
- [ ] Device real validado (comando documentado): `opencode --version` e teste manual de 3-5 skills

---

## Notas

- Este plano NÃO implementa nada — apenas planeja. A implementação será delegada ao agente `dev` via `task-build`.
- O device real (Termux) não está acessível neste momento. A validação final será documentada como comando para execução posterior.
- Priorizar estabilidade: não instalar skills novas sem necessidade concreta.
