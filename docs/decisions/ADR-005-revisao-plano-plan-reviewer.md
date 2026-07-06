# ADR-005: Revisão de Plano via plan-reviewer

## Status
Accepted

## Date
2026-07-05

## Context
Planos gerados por `task-planner` podem conter erros, omissões ou abordagens subóptimas. Sem revisão, problemas só são descobertos durante a implementação, causando retrabalho.

## Decision
Usar skill `plan-reviewer` no Step 4b do workflow para revisar planos antes da implementação. A revisão verifica completude, consistência e aderência ao template.

## Alternatives Considered
- Sem revisão — Rejeitado: risco de planos deficientes, retrabalho caro
- Revisão manual pelo usuário — Rejeitado: bottleneck, inconsistente
- Revisão automática por lint — Rejeitado: não detecta problemas semânticos

## Consequences
- **Positivo**: Planos verificados antes da implementação
- **Positivo**: Redução de retrabalho
- **Positivo**: Padrão de qualidade consistente
- **Negativo**: Tempo adicional no pipeline (3min para revisão)
- **Negativo**: Dependência de uma skill adicional

## Related
- [ADR-001](ADR-001-loop-de-trabalho-vs-task-build.md) — Pipeline que inclui revisão
- [ADR-006](ADR-006-gate-dinamico-pos-revisao.md) — Decisão pós-revisão