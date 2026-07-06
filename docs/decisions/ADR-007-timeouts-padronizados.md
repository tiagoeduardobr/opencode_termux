# ADR-007: Timeouts Padronizados

## Status
Accepted

## Date
2026-07-05

## Context
Diferentes agentes têm necessidades de tempo diferentes. Sem timeouts padrão, processos podem ficar pendurados indefinidamente, bloqueando o pipeline.

## Decision
Definir timeouts padrão por agente:
- `task-planner`: 5 min
- `plan-reviewer`: 3 min
- `dev`: 10 min/task
- `code-review (plano)`: 10 min
- `code-review (código)`: 5 min
- `git-commit`: 5 min

Timeouts são configuráveis via config do agente.

## Alternatives Considered
- Timeouts uniformes (ex: 3min para tudo) — Rejeitado: ineficiente para tarefas complexas
- Sem timeouts — Rejeitado: processos podem ficar pendurados
- Timeouts por arquivo — Rejeitado: complexidade desnecessária

## Consequences
- **Positivo**: Processos não ficam pendurados indefinidamente
- **Positivo**: Tempo adequado para cada tipo de operação
- **Positivo**: Configuração centralizada e consistente
- **Negativo**: Pode interromper operações legítimas em casos extremos
- **Negativo**: Valores fixos podem não ser ideais para todos os cenários

## Related
- [ADR-001](ADR-001-loop-de-trabalho-vs-task-build.md) — Pipeline que requer timeouts