# ADR-001: Padronizar loop de trabalho em relação ao workflow do task-build

## Status
Accepted

## Date
2026-06-30

## Context
O `AGENTS.md` apresentava um "Loop de trabalho" genérico e pointer para outro documento, enquanto `task-build.md` definia o workflow detalhado com passos 0–8. Isso gerava ambiguidade sobre qual fluxo seguir ao usar o agente `task-build` e quais etapas eram obrigatórias (por exemplo, gate de aprovação do plano e revisão consolidada).

## Decision
Manter o loop de trabalho no `AGENTS.md` como referência rápida alinhada ao workflow do `task-build.md` (passos 0–8), com mapeamento explícito e notas:
- O loop resumido cobre os passos essenciais (ler AGENTS, entender tarefa, planejar, aprovar plano, branch, implementar, revisar, revisão consolidada, commit e relatório).
- O `task-build.md` continua sendo a fonte de verdade para o fluxo detalhado, incluindo gates, retries e regras de orquestração.
- Para fluxos simples (sem `task-build`), manter referência ao `docs/MULTI_AGENT_ORCHESTRATION.md`.

## Alternatives Considered
### Manter apenas o ponteiro para `MULTI_AGENT_ORCHESTRATION.md`
- Pros: evita duplicação.
- Cons: não garante visibilidade imediata dos passos críticos no `AGENTS.md`.

### Sincronizar apenas Sumário sem mapeamento explícito
- Pros: mudança menor.
- Cons: continuaria ambíguo para quem precisa de rastreabilidade entre os dois documentos.

## Consequences
- `AGENTS.md` passa a refletir, de forma concisa, os passos esperados no pipeline orquestrado.
- Reduz divergências e melhora a aderência ao workflow definido em `task-build.md`.
- Mantém o `AGENTS.md` como visão de alto nível, sem copiar todo o detalhamento do `task-build.md`.
