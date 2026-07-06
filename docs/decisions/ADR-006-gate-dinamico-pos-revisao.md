# ADR-006: Gate Dinâmico Pós-Revisão

## Status
Accepted

## Date
2026-07-05

## Context
Após a revisão do plano (Step 4b), é necessário decidir se o plano está pronto para implementação, se precisa de refinamento, ou se deve ser rejeitado. Sem este gate, planos problemáticos avançam para implementação.

## Decision
Implementar gate dinâmico (Step 4c) que avalia o resultado da revisão. O gate pode: aprovar (avançar), solicitar refinamento (voltar ao task-planner), ou rejeitar (parar). As opções do QUESTION TOOL são geradas contextuais baseadas no veredito da revisão.

## Alternatives Considered
- Aprovação automática — Rejeitado: perde controle de qualidade
- Aprovação sempre manual — Rejeitado: bottleneck
- Sem gate — Rejeitado: planos problemáticos avançam

## Consequences
- **Positivo**: Controle de qualidade antes da implementação
- **Positivo**: Flexibilidade para refinar planos
- **Positivo**: Evita implementação de planos deficientes
- **Negativo**: Complexidade adicional no workflow
- **Negativo**: Pode causar loops se a revisão sempre pedir refinamento

## Related
- [ADR-001](ADR-001-loop-de-trabalho-vs-task-build.md) — Pipeline com gates
- [ADR-005](ADR-005-revisao-plano-plan-reviewer.md) — Revisão que alimenta o gate
