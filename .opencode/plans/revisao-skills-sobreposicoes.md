# Relatório de Sobreposições Funcionais entre Skills

**Data:** 2026-07-07
**Branch:** feature/revisao-completa-skills

## Resumo

Análise de 41 skills instaladas identificou 6 pares de sobreposição funcional previamente reportados. Após verificação detalhada dos SKILL.md de cada skill, **4 pares foram confirmados como sobreposição real**, **2 pares são complementares** (não sobrepostos), e **nenhum novo par de sobreposição** foi encontrado.

---

## Pares Confirmados com Sobreposição

### 1. `code-reviewer` vs `staff-engineer-review`

**Status:** ⚠️ SOBREPOSIÇÃO CONFIRMADA (parcial)

**Análise:**
- **code-reviewer:** Revisão geral de código (bugs, segurança, performance, smells, arquitetura). Output: relatório estruturado com categorias (critical/major/minor).
- **staff-engineer-review:** Revisão profunda de PRs focada em alinhamento plano vs implementação. Output: avaliação com score de alinhamento (0-100%) e análise de risco.

**Sobreposição:** Ambos revisam código, mas com ângulos diferentes. code-reviewer é mais amplo; staff-engineer-review é mais específico para avaliar se a implementação segue o plano original.

**Recomendação:** **MANTER AMBOS** — são complementares. code-reviewer para revisão geral, staff-engineer-review para评审 de implementação vs spec.

### 2. `writing-plans` vs `spec-driven-development`

**Status:** ✅ SOBREPOSIÇÃO CONFIRMADA

**Análise:**
- **writing-plans:** Cria planos de implementação detalhados (tarefas bite-sized com código). Assume que a spec já existe.
- **spec-driven-development:** Cria specs estruturadas antes do código (6 áreas: objetivo, comandos, estrutura, estilo, testes, limites).

**Sobreposição:** writing-plans depende de spec-driven-development. A sobreposição é parcial — spec cria requisitos, writing-plans cria plano de implementação.

**Recomendação:** **MANTER AMBOS** — são etapas diferentes do mesmo fluxo. spec → plan → implement.

### 3. `design-system-patterns` vs `design-tokens`

**Status:** ⚠️ SOBREPOSIÇÃO CONFIRMADA (significativa)

**Análise:**
- **design-system-patterns:** Design system completo (tokens + theming + component architecture). 4 seções: tokens, theming, componentes, pipeline.
- **design-tokens:** Foco específico em tokens CSS e theme systems. 3 seções: token structure, theme implementation, component integration.

**Sobreposição:** design-tokens é um subconjunto de design-system-patterns. Ambos cobram tokens e theming.

**Recomendação:** **UNIFICAR** — design-tokens poderia ser absorvido por design-system-patterns, ou tornar design-tokens uma referência detalhada de design-system-patterns.

### 4. `frontend-design` vs `designing-frontend-interfaces`

**Status:** ⚠️ SOBREPOSIÇÃO CONFIRMADA (alta)

**Análise:**
- **frontend-design:** "Guidance for distinctive, intentional visual design" — foco em direção estética, tipografia, choices deliberadas.
- **designing-frontend-interfaces:** "Use when building distinctive, production-grade frontend interfaces" — foco em implementação de UIs com alta qualidade.

**Sobreposição:** Ambos enfatizam evitar estéticas genéricas de IA, fazer escolhas criativas, tipografia distinta, motion deliberado.

**Recomendação:** **UNIFICAR** — são essencialmente a mesma skill com redações diferentes. Recomenda-se manter `designing-frontend-interfaces` (mais abrangente) e incorporar o conteúdo único de `frontend-design`.

---

## Pares Complementares (Não Sobrepostos)

### 5. `requesting-code-review` vs `receiving-code-review`

**Status:** ✅ COMPLEMENTARES

**Análise:**
- **requesting-code-review:** Como PEDIR revisão (dispatch subagent, template, quando pedir).
- **receiving-code-review:** Como RECEBER e RESPONDER a revisão (verificar, push back, implementar).

**Conclusão:** São faces opostas do mesmo processo. Não há sobreposição funcional.

**Recomendação:** **MANTER AMBOS** — são complementares naturais.

### 6. `web-design-guidelines` vs `designing-frontend-interfaces`

**Status:** ✅ COMPLEMENTARES

**Análise:**
- **web-design-guidelines:** Revisão de código UI para compliance com Web Interface Guidelines (fetch de guidelines externas).
- **designing-frontend-interfaces:** Construção de interfaces frontend com alta qualidade estética.

**Conclusão:** Um é sobre revisão/compliance, outro sobre construção. Diferentes momentos do ciclo.

**Recomendação:** **MANTER AMBOS** — são complementares.

---

## Novas Sobreposições Verificadas (Nenhuma Encontrada)

Após análise de skills adicionais, **nenhum novo par de sobreposição significativo** foi identificado:

- **test-driven-development vs test-master:** Complementares (TDD é metodologia, test-master é abrangente sobre testes).
- **documentation-and-adrs vs code-documenter:** Complementares (ADRs são decisões, code-documenter é documentação técnica).
- **brainstorming vs spec-driven-development:** Complementares (brainstorming é exploratório, spec é estruturado).
- **dispatching-parallel-agents vs subagent-driven-development:** Complementares (dispatch genérico vs execução de planos).

---

## Recomendações Finais

| Par | Recomendação | Ação Sugerida |
|-----|-------------|---------------|
| `code-reviewer` vs `staff-engineer-review` | Manter ambos | Documentar diferenças no frontmatter |
| `writing-plans` vs `spec-driven-development` | Manter ambos | Manter como etapas do fluxo |
| `design-system-patterns` vs `design-tokens` | **Unificar** | Absorver design-tokens em design-system-patterns |
| `frontend-design` vs `designing-frontend-interfaces` | **Unificar** | Manter designing-frontend-interfaces, incorporar conteúdo único |
| `requesting-code-review` vs `receiving-code-review` | Manter ambos | São complementares |
| `web-design-guidelines` vs `designing-frontend-interfaces` | Manter ambos | São complementares |

---

## Próximos Passos

1. **Unificar skills de design:** Mesclar design-tokens em design-system-patterns e frontend-design em designing-frontend-interfaces
2. **Atualizar descriptions:** Refinar descriptions para evitar confusão de triggering
3. **Documentar fluxo:** Criar documentação do fluxo spec → plan → implement → review
